import Foundation

public struct GuestStatus: Identifiable, Hashable, Sendable {
    public let vmid: Int
    public let name: String?
    public let status: String
    public let qmpStatus: String?
    public let lock: String?
    public let tags: [String]

    public let cpu: Double?
    public let cpus: Double?
    public let mem: Int64?
    public let maxmem: Int64?
    public let hostMemory: Int64?
    public let swap: Int64?
    public let maxswap: Int64?
    public let disk: Int64?
    public let maxdisk: Int64?
    public let uptime: Int?

    public let networkIn: Int64?
    public let networkOut: Int64?
    public let diskRead: Int64?
    public let diskWritten: Int64?

    public let isManagedByHA: Bool
    public let hasGuestAgent: Bool

    public init(
        vmid: Int,
        name: String? = nil,
        status: String,
        qmpStatus: String? = nil,
        lock: String? = nil,
        tags: [String] = [],
        cpu: Double? = nil,
        cpus: Double? = nil,
        mem: Int64? = nil,
        maxmem: Int64? = nil,
        hostMemory: Int64? = nil,
        swap: Int64? = nil,
        maxswap: Int64? = nil,
        disk: Int64? = nil,
        maxdisk: Int64? = nil,
        uptime: Int? = nil,
        networkIn: Int64? = nil,
        networkOut: Int64? = nil,
        diskRead: Int64? = nil,
        diskWritten: Int64? = nil,
        isManagedByHA: Bool = false,
        hasGuestAgent: Bool = false
    ) {
        self.vmid = vmid
        self.name = name
        self.status = status
        self.qmpStatus = qmpStatus
        self.lock = lock
        self.tags = tags
        self.cpu = cpu
        self.cpus = cpus
        self.mem = mem
        self.maxmem = maxmem
        self.hostMemory = hostMemory
        self.swap = swap
        self.maxswap = maxswap
        self.disk = disk
        self.maxdisk = maxdisk
        self.uptime = uptime
        self.networkIn = networkIn
        self.networkOut = networkOut
        self.diskRead = diskRead
        self.diskWritten = diskWritten
        self.isManagedByHA = isManagedByHA
        self.hasGuestAgent = hasGuestAgent
    }

    public var id: Int { vmid }

    public var isRunning: Bool { status == "running" }

    public var isLocked: Bool { !(lock ?? "").isEmpty }
}
