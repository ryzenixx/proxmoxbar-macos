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
        case awaitingTrust(ServerCertificate, [TrustProblem])
        case failed(String)
        case saved
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
    @ObservationIgnored private var pendingFingerprint: String?
    @ObservationIgnored private var fingerprintAddress: String?

    init(mode: Mode = .adding, api: any ProxmoxAPI, store: ServerStore) {
        self.mode = mode
        self.api = api
        self.store = store
        if case .editing(let configuration) = mode {
            name = configuration.name
            address = configuration.address
            tokenIdentifier = configuration.tokenIdentifier
            pendingFingerprint = configuration.pinnedFingerprint
            fingerprintAddress = configuration.address
        }
    }

    var isEditing: Bool {
        if case .editing = mode { return true }
        return false
    }

    var canSubmit: Bool {
        phase != .checking && credentials != nil
    }

    var isChecking: Bool {
        phase == .checking
    }

    var hasUsableAddress: Bool {
        ServerCredentials(address: address, tokenIdentifier: "x", secret: "x") != nil
    }

    var keepsExistingSecret: Bool {
        isEditing && secret.isEmpty
    }

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespaces)
    }

    private var effectiveSecret: String? {
        guard secret.isEmpty else { return secret }
        guard case .editing(let configuration) = mode else { return nil }
        return (try? store.secret(for: configuration.id)) ?? nil
    }

    private var credentials: ServerCredentials? {
        guard let effectiveSecret else { return nil }
        return ServerCredentials(
            address: address,
            tokenIdentifier: tokenIdentifier,
            secret: effectiveSecret
        )
    }

    func connect() async {
        guard let credentials else {
            phase = .failed(ProxmoxError.invalidURL.localizedDescription)
            return
        }
        if fingerprintAddress != trimmedAddress {
            pendingFingerprint = nil
            fingerprintAddress = nil
        }
        phase = .checking
        let server = ProxmoxServer(
            credentials: credentials,
            pinnedFingerprint: pendingFingerprint
        )
        do {
            let version = try await api.version(of: server)
            let summary = try? await api.clusterState(of: server)
            try save(credentials: credentials)
            self.version = version
            self.summary = summary
            self.savedName = displayName(for: credentials)
            phase = .saved
        } catch let error as ProxmoxError {
            handle(error)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func trustPresentedCertificate() async {
        guard case .awaitingTrust(let certificate, _) = phase else { return }
        pendingFingerprint = certificate.fingerprint
        fingerprintAddress = trimmedAddress
        await connect()
    }

    func cancelTrust() {
        pendingFingerprint = nil
        fingerprintAddress = nil
        phase = .editing
    }

    func resetError() {
        guard case .failed = phase else { return }
        phase = .editing
    }

    private func handle(_ error: ProxmoxError) {
        if case .untrustedCertificate(let certificate, let problems) = error {
            phase = .awaitingTrust(certificate, problems)
            return
        }
        phase = .failed(error.localizedDescription)
    }

    private func save(credentials: ServerCredentials) throws {
        switch mode {
        case .adding:
            let configuration = ServerConfiguration(
                name: displayName(for: credentials),
                address: trimmedAddress,
                tokenIdentifier: credentials.tokenIdentifier,
                pinnedFingerprint: pendingFingerprint
            )
            try store.add(configuration, secret: credentials.secret)
        case .editing(let existing):
            var updated = existing
            updated.name = displayName(for: credentials)
            updated.address = trimmedAddress
            updated.tokenIdentifier = credentials.tokenIdentifier
            updated.pinnedFingerprint = pendingFingerprint
            try store.update(updated, secret: secret.isEmpty ? nil : secret)
        }
    }

    private func displayName(for credentials: ServerCredentials) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty else { return trimmed }
        return credentials.baseURL.host() ?? "Proxmox"
    }
}
