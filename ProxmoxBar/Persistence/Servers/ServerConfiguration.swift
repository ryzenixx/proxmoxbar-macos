import Foundation

struct ServerConfiguration: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var address: String
    var tokenIdentifier: String
    var pinnedFingerprint: String?

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        tokenIdentifier: String,
        pinnedFingerprint: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.tokenIdentifier = tokenIdentifier
        self.pinnedFingerprint = pinnedFingerprint
    }

    var displayName: String {
        name.isEmpty ? address : name
    }

    func server(withSecret secret: String) -> ProxmoxServer? {
        guard
            let credentials = ServerCredentials(
                address: address,
                tokenIdentifier: tokenIdentifier,
                secret: secret
            )
        else { return nil }
        return ProxmoxServer(credentials: credentials, pinnedFingerprint: pinnedFingerprint)
    }
}
