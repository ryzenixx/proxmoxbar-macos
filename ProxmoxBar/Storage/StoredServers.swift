import Foundation

struct StoredServers: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let servers: [ServerConfiguration]

    init(servers: [ServerConfiguration]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.servers = servers
    }

    var isReadable: Bool {
        schemaVersion <= Self.currentSchemaVersion
    }
}
