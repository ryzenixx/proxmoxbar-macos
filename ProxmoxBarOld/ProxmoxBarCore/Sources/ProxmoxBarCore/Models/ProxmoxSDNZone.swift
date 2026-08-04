import Foundation

public struct ProxmoxSDNZone: Identifiable, Codable, Hashable, Sendable {
    public let sdn: String
    public let node: String?
    public let status: String?
    public let zoneType: String?

    public init(sdn: String, node: String? = nil, status: String? = nil, zoneType: String? = nil) {
        self.sdn = sdn
        self.node = node
        self.status = status
        self.zoneType = zoneType
    }

    public var id: String {
        guard let node else { return sdn }
        return "\(node)-\(sdn)"
    }

    public var isAvailable: Bool { status == "available" }
}
