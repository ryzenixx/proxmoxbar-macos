import Foundation

public struct ProxmoxNetwork: Identifiable, Codable, Hashable, Sendable {
    public let network: String
    public let node: String?
    public let status: String?
    public let networkType: String?
    public let networkProtocol: String?

    public init(
        network: String,
        node: String? = nil,
        status: String? = nil,
        networkType: String? = nil,
        networkProtocol: String? = nil
    ) {
        self.network = network
        self.node = node
        self.status = status
        self.networkType = networkType
        self.networkProtocol = networkProtocol
    }

    public var id: String {
        guard let node else { return network }
        return "\(node)-\(network)"
    }
}
