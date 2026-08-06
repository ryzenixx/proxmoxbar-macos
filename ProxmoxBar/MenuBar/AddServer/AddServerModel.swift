import Foundation
import Observation

@MainActor
@Observable
final class AddServerModel {
    enum Phase: Equatable {
        case editing
        case checking
        case awaitingTrust(ServerCertificate, [TrustProblem])
        case failed(String)
        case added
    }

    var name = ""
    var address = ""
    var tokenIdentifier = ""
    var secret = ""

    private(set) var phase: Phase = .editing
    private(set) var version: ServerVersion?
    private(set) var summary: ClusterState?
    private(set) var addedName = ""

    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private var pendingFingerprint: String?

    init(api: any ProxmoxAPI, store: ServerStore) {
        self.api = api
        self.store = store
    }

    var canSubmit: Bool {
        guard phase != .checking else { return false }
        return credentials != nil && secret.isEmpty == false
    }

    var isChecking: Bool {
        phase == .checking
    }

    var hasUsableAddress: Bool {
        ServerCredentials(address: address, tokenIdentifier: "x", secret: "x") != nil
    }

    private var credentials: ServerCredentials? {
        ServerCredentials(
            address: address,
            tokenIdentifier: tokenIdentifier,
            secret: secret
        )
    }

    func connect() async {
        guard let credentials else {
            phase = .failed(ProxmoxError.invalidURL.localizedDescription)
            return
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
            self.addedName = displayName(for: credentials)
            phase = .added
        } catch let error as ProxmoxError {
            handle(error)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func trustPresentedCertificate() async {
        guard case .awaitingTrust(let certificate, _) = phase else { return }
        pendingFingerprint = certificate.fingerprint
        await connect()
    }

    func cancelTrust() {
        pendingFingerprint = nil
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
        let configuration = ServerConfiguration(
            name: displayName(for: credentials),
            address: address.trimmingCharacters(in: .whitespaces),
            tokenIdentifier: credentials.tokenIdentifier,
            pinnedFingerprint: pendingFingerprint
        )
        try store.add(configuration, secret: credentials.secret)
    }

    private func displayName(for credentials: ServerCredentials) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty else { return trimmed }
        return credentials.baseURL.host() ?? "Proxmox"
    }
}
