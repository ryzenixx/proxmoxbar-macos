import Foundation

public struct ProxmoxStorage: Identifiable, Codable, Hashable, Sendable {
    public var id: String { "\(node)-\(storage)" }
    public let storage: String
    public let node: String
    public let status: String

    public let disk: Int64?
    public let maxdisk: Int64?
    public let type: String?
    public let content: String?

    public init(
        storage: String,
        node: String,
        status: String,
        disk: Int64?,
        maxdisk: Int64?,
        type: String?,
        content: String?
    ) {
        self.storage = storage
        self.node = node
        self.status = status
        self.disk = disk
        self.maxdisk = maxdisk
        self.type = type
        self.content = content
    }

    public var isAvailable: Bool { status == "available" }

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
