import Foundation

struct ClusterResource: Decodable, Sendable {
    enum Kind: String, Decodable, Sendable {
        case node
        case storage
        case pool
        case qemu
        case lxc
        case openvz
        case sdn
        case network
    }

    let id: String
    let type: Kind

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
    let memhost: Int?
    let disk: Int?
    let maxdisk: Int?

    let netin: Int?
    let netout: Int?
    let diskread: Int?
    let diskwrite: Int?

    let storage: String?
    let content: String?
    let plugintype: String?
    let shared: ProxmoxBoolean?

    let level: String?
    let cgroupMode: Int?
    let hostArch: String?

    let sdn: String?
    let zoneType: String?
    let network: String?
    let networkType: String?
    let protocolName: String?

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
        case id, type, name, node, status, uptime, lock, tags, pool, hastate
        case vmid, template
        case cpu, maxcpu, mem, maxmem, memhost, disk, maxdisk
        case netin, netout, diskread, diskwrite
        case storage, content, plugintype, shared
        case level
        case cgroupMode = "cgroup-mode"
        case hostArch = "host-arch"
        case sdn
        case zoneType = "zone-type"
        case network
        case networkType = "network-type"
        case protocolName = "protocol"
    }
}
