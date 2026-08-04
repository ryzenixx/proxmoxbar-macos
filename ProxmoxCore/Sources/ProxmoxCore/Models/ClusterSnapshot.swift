import Foundation

public struct ClusterSnapshot: Sendable, Equatable {
    public let nodes: [ProxmoxNode]
    public let storages: [ProxmoxStorage]
    public let guests: [ProxmoxGuest]
    public let pools: [ProxmoxPool]
    public let sdnZones: [ProxmoxSDNZone]
    public let networks: [ProxmoxNetwork]

    public init(
        nodes: [ProxmoxNode] = [],
        storages: [ProxmoxStorage] = [],
        guests: [ProxmoxGuest] = [],
        pools: [ProxmoxPool] = [],
        sdnZones: [ProxmoxSDNZone] = [],
        networks: [ProxmoxNetwork] = []
    ) {
        self.nodes = nodes
        self.storages = storages
        self.guests = guests
        self.pools = pools
        self.sdnZones = sdnZones
        self.networks = networks
    }

    public static let empty = ClusterSnapshot()
}
