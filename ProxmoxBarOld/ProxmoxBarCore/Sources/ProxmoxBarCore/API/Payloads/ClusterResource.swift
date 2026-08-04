import Foundation

struct ClusterResource: Decodable {
    let id: String
    let type: String
    let status: String?
    let node: String?
    let name: String?

    let vmid: Int?
    let pool: String?
    let tags: String?
    let template: ProxmoxBoolean?
    let lock: String?
    let hastate: String?

    let cpu: Double?
    let maxcpu: Double?
    let mem: Int64?
    let maxmem: Int64?
    let memhost: Int64?
    let disk: Int64?
    let maxdisk: Int64?
    let uptime: Int?

    let netin: Int64?
    let netout: Int64?
    let diskread: Int64?
    let diskwrite: Int64?

    let storage: String?
    let plugintype: String?
    let content: String?
    let shared: ProxmoxBoolean?

    let level: String?
    let hostArchitecture: String?
    let cgroupMode: Int?

    let sdn: String?
    let zoneType: String?
    let network: String?
    let networkType: String?
    let netProtocol: String?

    enum CodingKeys: String, CodingKey {
        case id, type, status, node, name
        case vmid, pool, tags, template, lock, hastate
        case cpu, maxcpu, mem, maxmem, memhost, disk, maxdisk, uptime
        case netin, netout, diskread, diskwrite
        case storage, plugintype, content, shared
        case level
        case hostArchitecture = "host-arch"
        case cgroupMode = "cgroup-mode"
        case sdn
        case zoneType = "zone-type"
        case network
        case networkType = "network-type"
        case netProtocol = "protocol"
    }
}
