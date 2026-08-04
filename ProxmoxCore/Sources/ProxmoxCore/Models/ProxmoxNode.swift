import Foundation

public struct ProxmoxNode: Identifiable, Codable, Hashable, Sendable {
    public var id: String { node }
    public let node: String
    public let status: String

    public let cpu: Double?
    public let maxcpu: Double?
    public let mem: Int64?
    public let maxmem: Int64?
    public let disk: Int64?
    public let maxdisk: Int64?

    public init(
        node: String,
        status: String,
        cpu: Double?,
        maxcpu: Double?,
        mem: Int64?,
        maxmem: Int64?,
        disk: Int64?,
        maxdisk: Int64?
    ) {
        self.node = node
        self.status = status
        self.cpu = cpu
        self.maxcpu = maxcpu
        self.mem = mem
        self.maxmem = maxmem
        self.disk = disk
        self.maxdisk = maxdisk
    }

    public var isOnline: Bool { status == "online" }

    public var cpuUsage: Double {
        cpu ?? 0
    }

    public var cpuUsageFormatted: String {
        String(format: "%.1f%%", cpuUsage * 100)
    }

    public var memUsage: Double {
        guard let mem, let maxmem, maxmem > 0 else { return 0 }
        return Double(mem) / Double(maxmem)
    }

    public var memUsageFormatted: String {
        guard let mem, let maxmem, maxmem > 0 else { return "-" }
        let percent = (Double(mem) / Double(maxmem)) * 100
        return String(format: "%.0f%%", percent)
    }

    public var diskUsage: Double {
        guard let disk, let maxdisk, maxdisk > 0 else { return 0 }
        return Double(disk) / Double(maxdisk)
    }

    public var diskUsageFormatted: String {
        guard let disk, let maxdisk, maxdisk > 0 else { return "-" }
        let percent = (Double(disk) / Double(maxdisk)) * 100
        return String(format: "%.0f%%", percent)
    }
}
