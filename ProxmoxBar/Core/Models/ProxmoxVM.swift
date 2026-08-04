import Foundation

struct ProxmoxVM: Identifiable, Codable, Hashable {
    let vmid: Int
    let name: String
    let status: String
    let type: String
    let node: String

    let cpu: Double?
    let maxcpu: Double?
    let mem: Int64?
    let maxmem: Int64?
    let disk: Int64?
    let maxdisk: Int64?

    var serverId: UUID?

    var id: String {
        if let serverId {
            return "\(serverId)-\(node)-\(vmid)"
        }
        return "\(node)-\(vmid)"
    }

    var isRunning: Bool { status == "running" }

    var memoryRatio: Double {
        guard let mem, let maxmem, maxmem > 0 else { return 0 }
        return Double(mem) / Double(maxmem)
    }

    var diskRatio: Double? {
        guard let disk, let maxdisk, maxdisk > 0 else { return nil }
        return Double(disk) / Double(maxdisk)
    }

    var cpuUsage: String {
        guard let cpu else { return "-" }
        return String(format: "%.1f%%", cpu * 100)
    }

    var memUsage: String {
        guard let mem, let maxmem, maxmem > 0 else { return "-" }
        let percent = Double(mem) / Double(maxmem) * 100
        return String(format: "%.0f%%", percent)
    }

    var diskUsage: String {
        guard let disk, let maxdisk, maxdisk > 0 else { return "-" }
        let percent = Double(disk) / Double(maxdisk) * 100
        return String(format: "%.0f%%", percent)
    }
}
