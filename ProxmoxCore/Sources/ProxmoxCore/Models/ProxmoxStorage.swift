import Foundation

public struct ProxmoxStorage: Identifiable, Codable, Hashable, Sendable {
    public let storage: String
    public let node: String
    public let status: String

    public let disk: Int64?
    public let maxdisk: Int64?
    public let pluginType: String?
    public let contentTypes: [String]
    public let isShared: Bool

    public init(
        storage: String,
        node: String,
        status: String,
        disk: Int64? = nil,
        maxdisk: Int64? = nil,
        pluginType: String? = nil,
        contentTypes: [String] = [],
        isShared: Bool = false
    ) {
        self.storage = storage
        self.node = node
        self.status = status
        self.disk = disk
        self.maxdisk = maxdisk
        self.pluginType = pluginType
        self.contentTypes = contentTypes
        self.isShared = isShared
    }

    public var id: String { "\(node)-\(storage)" }

    public var isAvailable: Bool { status == "available" }

    public var diskUsage: Double {
        guard let disk, let maxdisk, maxdisk > 0 else { return 0 }
        return Double(disk) / Double(maxdisk)
    }

    public var diskUsageFormatted: String {
        guard disk != nil, let maxdisk, maxdisk > 0 else { return "-" }
        return String(format: "%.0f%%", diskUsage * 100)
    }
}
