import Foundation

enum ClusterResource: Decodable, Sendable {
    case node(Payload)
    case storage(Payload)
    case guest(GuestKind, Payload)
    case ignored

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "node": self = .node(try Payload(from: decoder))
        case "storage": self = .storage(try Payload(from: decoder))
        default:
            if let kind = GuestKind(rawValue: type) {
                self = .guest(kind, try Payload(from: decoder))
            } else {
                self = .ignored
            }
        }
    }

    struct Payload: Decodable, Sendable {
        let id: String
        let name: String?
        let node: String?
        let status: String?
        let uptime: Int?
        let lock: String?
        let tags: String?
        let pool: String?
        let hastate: String?
        let vmid: Int?
        let template: ProxmoxBoolean?

        let cpu: Double?
        let maxcpu: Double?
        let mem: Int?
        let maxmem: Int?
        let disk: Int?
        let maxdisk: Int?

        let storage: String?
        let content: String?
        let plugintype: String?
        let shared: ProxmoxBoolean?
        let level: String?
        let hostArch: String?

        var tagList: [String] {
            Self.split(tags)
        }

        var contentList: [String] {
            Self.split(content)
        }

        private static func split(_ field: String?) -> [String] {
            guard let field else { return [] }
            return
                field
                .split(whereSeparator: { $0 == "," || $0 == ";" })
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.isEmpty == false }
        }

        enum CodingKeys: String, CodingKey {
            case id, name, node, status, uptime, lock, tags, pool, hastate
            case vmid, template
            case cpu, maxcpu, mem, maxmem, disk, maxdisk
            case storage, content, plugintype, shared
            case level
            case hostArch = "host-arch"
        }
    }
}
