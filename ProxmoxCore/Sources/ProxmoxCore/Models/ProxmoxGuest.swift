import Foundation

public struct ProxmoxGuest: Identifiable, Codable, Hashable, Sendable {
    public let vmid: Int
    public let name: String?
    public let status: String
    public let type: GuestKind
    public let node: String

    public let pool: String?
    public let tags: [String]
    public let isTemplate: Bool
    public let lock: String?
    public let haState: String?

    public let cpu: Double?
    public let maxcpu: Double?
    public let mem: Int64?
    public let maxmem: Int64?
    public let hostMemory: Int64?
    public let disk: Int64?
    public let maxdisk: Int64?
    public let uptime: Int?

    public let networkIn: Int64?
    public let networkOut: Int64?
    public let diskRead: Int64?
    public let diskWritten: Int64?

    public var serverId: UUID?

    public init(
        vmid: Int,
        name: String?,
        status: String,
        type: GuestKind,
        node: String,
        pool: String? = nil,
        tags: [String] = [],
        isTemplate: Bool = false,
        lock: String? = nil,
        haState: String? = nil,
        cpu: Double? = nil,
        maxcpu: Double? = nil,
        mem: Int64? = nil,
        maxmem: Int64? = nil,
        hostMemory: Int64? = nil,
        disk: Int64? = nil,
        maxdisk: Int64? = nil,
        uptime: Int? = nil,
        networkIn: Int64? = nil,
        networkOut: Int64? = nil,
        diskRead: Int64? = nil,
        diskWritten: Int64? = nil,
        serverId: UUID? = nil
    ) {
        self.vmid = vmid
        self.name = name
        self.status = status
        self.type = type
        self.node = node
        self.pool = pool
        self.tags = tags
        self.isTemplate = isTemplate
        self.lock = lock
        self.haState = haState
        self.cpu = cpu
        self.maxcpu = maxcpu
        self.mem = mem
        self.maxmem = maxmem
        self.hostMemory = hostMemory
        self.disk = disk
        self.maxdisk = maxdisk
        self.uptime = uptime
        self.networkIn = networkIn
        self.networkOut = networkOut
        self.diskRead = diskRead
        self.diskWritten = diskWritten
        self.serverId = serverId
    }

    public var id: String {
        if let serverId {
            return "\(serverId)-\(node)-\(vmid)"
        }
        return "\(node)-\(vmid)"
    }

    public var displayName: String {
        guard let name, !name.isEmpty else { return "\(vmid)" }
        return name
    }

    public var isRunning: Bool { status == "running" }

    public var isVirtualMachine: Bool { type.isVirtualMachine }

    public var isContainer: Bool { type.isContainer }

    public var isLocked: Bool { !(lock ?? "").isEmpty }

    public var isHighlyAvailable: Bool { !(haState ?? "").isEmpty }

    public var acceptsPowerActions: Bool { !isTemplate && !isLocked }

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
        guard mem != nil, let maxmem, maxmem > 0 else { return "-" }
        return String(format: "%.0f%%", memoryRatio * 100)
    }

    public var diskUsage: String {
        guard let diskRatio else { return "-" }
        return String(format: "%.0f%%", diskRatio * 100)
    }
}
