import Foundation

struct ProxmoxServer: Hashable, Sendable {
    let credentials: ServerCredentials
    let pinnedFingerprint: String?

    init(credentials: ServerCredentials, pinnedFingerprint: String? = nil) {
        self.credentials = credentials
        self.pinnedFingerprint = pinnedFingerprint
    }

    func trusting(_ fingerprint: String) -> ProxmoxServer {
        ProxmoxServer(credentials: credentials, pinnedFingerprint: fingerprint)
    }
}
