import Foundation

struct ProxmoxVM: Identifiable, Codable, Hashable {
    var id: String {
        if let serverId = serverId {
            return "\(serverId)-\(node)-\(vmid)"
        }
        return "\(node)-\(vmid)"
    }
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
    
    var serverId: UUID? = nil
    
    var apiType: String { return type }
    var isRunning: Bool { return status == "running" }
    
    var cpuUsage: String {
        guard let cpu = cpu else { return "-" }
        return String(format: "%.1f%%", cpu * 100)
    }
    
    var memUsage: String {
        guard let mem = mem, let maxmem = maxmem, maxmem > 0 else { return "-" }
        let percent = Double(mem) / Double(maxmem) * 100
        return String(format: "%.0f%%", percent)
    }
    
    var diskUsage: String {
        guard let disk = disk, let maxdisk = maxdisk, maxdisk > 0 else { return "-" }
        let percent = Double(disk) / Double(maxdisk) * 100
        return String(format: "%.0f%%", percent)
    }
}

struct ProxmoxRawResource: Codable {
    let id: String?
    let vmid: Int?
    let name: String?
    let status: String?
    let type: String?
    let node: String?
    
    let cpu: Double?
    let maxcpu: Double?
    let mem: Int64?
    let maxmem: Int64?
    let disk: Int64?
    let maxdisk: Int64?
    
    let storage: String?
    let plugintype: String?
    let content: String?
}

struct ProxmoxResourceResponse: Codable {
    let data: [ProxmoxRawResource]
}
