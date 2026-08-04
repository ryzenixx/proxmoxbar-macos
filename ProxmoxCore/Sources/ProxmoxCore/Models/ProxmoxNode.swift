import Foundation

public struct ProxmoxNode: Identifiable, Codable, Hashable, Sendable {
    public let node: String
    public let status: String

    public let cpu: Double?
    public let maxcpu: Double?
    public let mem: Int64?
    public let maxmem: Int64?
    public let disk: Int64?
    public let maxdisk: Int64?
    public let uptime: Int?

    public let supportLevel: String?
    public let hostArchitecture: String?
    public let cgroupMode: Int?

    public init(
        node: String,
        status: String,
        cpu: Double? = nil,
        maxcpu: Double? = nil,
        mem: Int64? = nil,
        maxmem: Int64? = nil,
        disk: Int64? = nil,
        maxdisk: Int64? = nil,
        uptime: Int? = nil,
        supportLevel: String? = nil,
        hostArchitecture: String? = nil,
        cgroupMode: Int? = nil
    ) {
        self.node = node
        self.status = status
        self.cpu = cpu
        self.maxcpu = maxcpu
        self.mem = mem
        self.maxmem = maxmem
        self.disk = disk
        self.maxdisk = maxdisk
        self.uptime = uptime
        self.supportLevel = supportLevel
        self.hostArchitecture = hostArchitecture
        self.cgroupMode = cgroupMode
    }

    public var id: String { node }

    public var isOnline: Bool { status == "online" }

    public var cpuUsage: Double { cpu ?? 0 }

    public var cpuUsageFormatted: String {
        String(format: "%.1f%%", cpuUsage * 100)
    }

    public var memUsage: Double {
        guard let mem, let maxmem, maxmem > 0 else { return 0 }
        return Double(mem) / Double(maxmem)
    }

    public var memUsageFormatted: String {
        guard mem != nil, let maxmem, maxmem > 0 else { return "-" }
        return String(format: "%.0f%%", memUsage * 100)
    }

    public var diskUsage: Double {
        guard let disk, let maxdisk, maxdisk > 0 else { return 0 }
        return Double(disk) / Double(maxdisk)
    }

    public var diskUsageFormatted: String {
        guard disk != nil, let maxdisk, maxdisk > 0 else { return "-" }
        return String(format: "%.0f%%", diskUsage * 100)
    }
}
