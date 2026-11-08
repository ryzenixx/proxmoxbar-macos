import Foundation

struct StoredServers: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let servers: [ServerConfiguration]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, servers
    }

    init(servers: [ServerConfiguration]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.servers = servers
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        servers =
            schemaVersion <= Self.currentSchemaVersion
            ? try values.decode([ServerConfiguration].self, forKey: .servers)
            : []
    }

    var isReadable: Bool {
        schemaVersion <= Self.currentSchemaVersion
    }
}
