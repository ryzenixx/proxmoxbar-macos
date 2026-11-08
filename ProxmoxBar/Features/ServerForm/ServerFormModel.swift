import Foundation
import Observation

@MainActor
@Observable
final class ServerFormModel {
    enum Mode: Hashable, Sendable {
        case adding
        case editing(ServerConfiguration)
    }

    enum Phase: Equatable {
        case editing
        case checking
        case awaitingTrust(approvalID: UUID, ServerCertificate, [TrustProblem])
        case failed(String)
        case saved
    }

    private struct Submission {
        let id = UUID()
        var configuration: ServerConfiguration
        let credentials: ServerCredentials
        let retainedSecret: String?

        var server: ProxmoxServer {
            ProxmoxServer(
                credentials: credentials,
                pinnedFingerprint: configuration.pinnedFingerprint
            )
        }
    }

    let mode: Mode

    var name = ""
    var address = ""
    var tokenIdentifier = ""
    var secret = ""

    private(set) var phase: Phase = .editing
    private(set) var version: ServerVersion?
    private(set) var summary: ClusterState?
    private(set) var savedName = ""

    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private var submission: Submission?
    @ObservationIgnored private var request: Task<Void, Never>?

    init(mode: Mode, api: any ProxmoxAPI, store: ServerStore) {
        self.mode = mode
        self.api = api
        self.store = store
        if case .editing(let configuration) = mode {
            name = configuration.name
            address = configuration.address
            tokenIdentifier = configuration.tokenIdentifier
        }
    }

    var isEditing: Bool { originalConfiguration != nil }

    var canSubmit: Bool {
        acceptsSubmission && store.writeError == nil && hasUsableAddress
            && (try? effectiveSecret()) != nil
    }

    var isChecking: Bool { phase == .checking }

    var hasUsableAddress: Bool {
        ServerCredentials.baseURL(for: address) != nil
    }

    var failureMessage: String? {
        if let error = store.writeError { return error.localizedDescription }
        if case .failed(let message) = phase { return message }
        return nil
    }

    private var originalConfiguration: ServerConfiguration? {
        if case .editing(let configuration) = mode { return configuration }
        return nil
    }

    private var acceptsSubmission: Bool {
        switch phase {
        case .editing, .failed: true
        case .checking, .awaitingTrust, .saved: false
        }
    }

    private func effectiveSecret() throws -> String? {
        if !secret.isEmpty { return secret }
        guard let originalConfiguration else { return nil }
        return try store.secret(for: originalConfiguration.id)
    }

    func connect() {
        guard acceptsSubmission else { return }
        do {
            verify(try makeSubmission())
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func trustPresentedCertificate(_ approvalID: UUID) {
        guard case .awaitingTrust(let currentID, let certificate, _) = phase,
            currentID == approvalID, var submission
        else { return }
        submission.configuration.pinnedFingerprint = certificate.fingerprint
        verify(submission)
    }

    func cancelSubmission() {
        guard submission != nil else { return }
        submission = nil
        request?.cancel()
        request = nil
        phase = .editing
    }

    private func makeSubmission() throws -> Submission {
        if let error = store.writeError { throw error }
        let address = address.trimmingCharacters(in: .whitespaces)
        guard let effectiveSecret = try effectiveSecret(),
            let credentials = ServerCredentials(
                address: address, tokenIdentifier: tokenIdentifier, secret: effectiveSecret
            )
        else { throw ProxmoxError.invalidURL }

        let original = originalConfiguration
        let name = name.trimmingCharacters(in: .whitespaces)
        let configuration = ServerConfiguration(
            id: original?.id ?? UUID(),
            name: name.isEmpty ? (credentials.baseURL.host() ?? "Proxmox") : name,
            address: address,
            tokenIdentifier: credentials.tokenIdentifier,
            pinnedFingerprint: original?.address == address ? original?.pinnedFingerprint : nil
        )
        return Submission(
            configuration: configuration,
            credentials: credentials,
            retainedSecret: secret.isEmpty ? effectiveSecret : nil
        )
    }

    private func verify(_ submission: Submission) {
        self.submission = submission
        phase = .checking
        request = Task { [weak self] in
            await self?.verifyConnection(submission)
        }
    }

    private func isCurrent(_ submission: Submission) -> Bool {
        self.submission?.id == submission.id && !Task.isCancelled
    }

    private func verifyConnection(_ submission: Submission) async {
        guard isCurrent(submission) else { return }
        let server = submission.server
        do {
            let version = try await api.version(of: server)
            guard isCurrent(submission) else { return }
            let summary = try? await api.clusterState(of: server)
            guard isCurrent(submission) else { return }

            try save(submission)
            request = nil
            self.submission = nil
            self.version = version
            self.summary = summary
            savedName = submission.configuration.name
            phase = .saved
        } catch {
            guard isCurrent(submission) else { return }
            request = nil
            if case ProxmoxError.untrustedCertificate(let certificate, let problems) = error {
                phase = .awaitingTrust(approvalID: UUID(), certificate, problems)
            } else {
                self.submission = nil
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func save(_ submission: Submission) throws {
        guard let originalConfiguration else {
            try store.add(submission.configuration, secret: submission.credentials.secret)
            return
        }
        guard store.servers.contains(originalConfiguration) else {
            throw ServerStore.WriteError.serverChanged
        }
        if let retainedSecret = submission.retainedSecret {
            guard try store.secret(for: originalConfiguration.id) == retainedSecret else {
                throw ServerStore.WriteError.serverChanged
            }
        }
        let newSecret = submission.retainedSecret == nil ? submission.credentials.secret : nil
        try store.update(submission.configuration, secret: newSecret)
    }
}
