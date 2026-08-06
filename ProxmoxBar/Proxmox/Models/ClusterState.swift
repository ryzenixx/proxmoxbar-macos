import Foundation

struct ClusterState: Hashable, Sendable {
    let nodes: [ProxmoxNode]
    let guests: [ProxmoxGuest]
    let storages: [ProxmoxStorage]
    let discardedCount: Int

    static let empty = ClusterState(nodes: [], guests: [], storages: [], discardedCount: 0)

    func applying(_ statuses: [String: GuestStatus]) -> ClusterState {
        guard !statuses.isEmpty else { return self }
        return ClusterState(
            nodes: nodes,
            guests: guests.map { guest in
                guard let status = statuses[guest.id] else { return guest }
                var confirmed = guest
                confirmed.status = status
                return confirmed
            },
            storages: storages,
            discardedCount: discardedCount
        )
    }
}

extension ClusterState {
    init(resources: [ClusterResource]) {
        var nodes: [ProxmoxNode] = []
        var guests: [ProxmoxGuest] = []
        var storages: [ProxmoxStorage] = []
        var discarded = 0

        for resource in resources {
            switch resource.type {
            case .node:
                guard let node = ProxmoxNode(resource: resource) else {
                    discarded += 1
                    continue
                }
                nodes.append(node)
            case .qemu, .lxc:
                guard let guest = ProxmoxGuest(resource: resource) else {
                    discarded += 1
                    continue
                }
                guests.append(guest)
            case .storage:
                storages.append(ProxmoxStorage(resource: resource))
            case .pool, .openvz, .sdn, .network:
                continue
            }
        }

        self.init(
            nodes: nodes.sorted { $0.name < $1.name },
            guests: guests.sorted { $0.vmid < $1.vmid },
            storages: storages.sorted {
                ($0.usage ?? 0, $1.name) > ($1.usage ?? 0, $0.name)
            },
            discardedCount: discarded
        )
    }
}

extension ProxmoxNode {
    fileprivate init?(resource: ClusterResource) {
        guard let name = resource.node ?? resource.name else { return nil }
        self.init(
            id: resource.id,
            name: name,
            status: resource.status ?? "unknown",
            cpu: resource.cpu,
            maxCPUs: resource.maxcpu,
            memory: resource.mem,
            maximumMemory: resource.maxmem,
            disk: resource.disk,
            maximumDisk: resource.maxdisk,
            uptime: resource.uptime,
            level: resource.level,
            architecture: resource.hostArch
        )
    }
}

extension ProxmoxGuest {
    fileprivate init?(resource: ClusterResource) {
        guard let vmid = resource.vmid,
            let kind = GuestKind(rawValue: resource.type.rawValue),
            let node = resource.node
        else { return nil }

        self.init(
            id: resource.id,
            vmid: vmid,
            kind: kind,
            node: node,
            name: resource.name,
            status: GuestStatus(rawValue: resource.status ?? "unknown"),
            isTemplate: resource.template?.value ?? false,
            lock: resource.lock,
            tags: resource.tagList,
            pool: resource.pool,
            haState: resource.hastate,
            cpu: resource.cpu,
            maxCPUs: resource.maxcpu,
            memory: resource.mem,
            maximumMemory: resource.maxmem,
            disk: resource.disk,
            maximumDisk: resource.maxdisk,
            uptime: resource.uptime
        )
    }
}

extension ProxmoxStorage {
    fileprivate init(resource: ClusterResource) {
        self.init(
            id: resource.id,
            name: resource.storage ?? resource.name ?? resource.id,
            node: resource.node,
            status: resource.status,
            used: resource.disk,
            total: resource.maxdisk,
            content: resource.contentList,
            pluginType: resource.plugintype,
            isShared: resource.shared?.value ?? false
        )
    }
}
