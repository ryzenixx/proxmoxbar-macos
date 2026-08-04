import Foundation

public struct ProxmoxVM: Identifiable, Codable, Hashable, Sendable {
    public let vmid: Int
    public let name: String
    public let status: String
    public let type: String
    public let node: String

    public let cpu: Double?
    public let maxcpu: Double?
    public let mem: Int64?
    public let maxmem: Int64?
    public let disk: Int64?
    public let maxdisk: Int64?

    /// Which configured server this guest was read from. Assigned by the caller
    /// after a fetch, because the API has no idea it is one of several.
    public var serverId: UUID?

    public init(
        vmid: Int,
        name: String,
        status: String,
        type: String,
        node: String,
        cpu: Double?,
        maxcpu: Double?,
        mem: Int64?,
        maxmem: Int64?,
        disk: Int64?,
        maxdisk: Int64?,
        serverId: UUID? = nil
    ) {
        self.vmid = vmid
        self.name = name
        self.status = status
        self.type = type
        self.node = node
        self.cpu = cpu
        self.maxcpu = maxcpu
        self.mem = mem
        self.maxmem = maxmem
        self.disk = disk
        self.maxdisk = maxdisk
        self.serverId = serverId
    }

    public var id: String {
        if let serverId {
            return "\(serverId)-\(node)-\(vmid)"
        }
        return "\(node)-\(vmid)"
    }

    public var isRunning: Bool { status == "running" }

    public var memoryRatio: Double {
        guard let mem, let maxmem, maxmem > 0 else { return 0 }
        return Double(mem) / Double(maxmem)
    }

    public var diskRatio: Double? {
        guard let disk, let maxdisk, maxdisk > 0 else { return nil }
        return Double(disk) / Double(maxdisk)
    }

    public var cpuUsage: String {
        guard let cpu else { return "-" }
        return String(format: "%.1f%%", cpu * 100)
    }

    public var memUsage: String {
        guard let mem, let maxmem, maxmem > 0 else { return "-" }
        let percent = Double(mem) / Double(maxmem) * 100
        return String(format: "%.0f%%", percent)
    }

    public var diskUsage: String {
        guard let disk, let maxdisk, maxdisk > 0 else { return "-" }
        let percent = Double(disk) / Double(maxdisk) * 100
        return String(format: "%.0f%%", percent)
    }
}
