extension ClusterState {
    init(resources: [ClusterResource]) {
        var nodes: [ProxmoxNode] = []
        var guests: [ProxmoxGuest] = []
        var storages: [ProxmoxStorage] = []

        for resource in resources {
            switch resource {
            case .node(let resource):
                guard let node = ProxmoxNode(resource: resource) else { continue }
                nodes.append(node)
            case .guest(let kind, let resource):
                guard let guest = ProxmoxGuest(resource: resource, kind: kind) else { continue }
                guests.append(guest)
            case .storage(let resource):
                storages.append(ProxmoxStorage(resource: resource))
            case .ignored:
                continue
            }
        }

        self.init(
            nodes: nodes.sorted { $0.name < $1.name },
            guests: guests.sorted { $0.vmid < $1.vmid },
            storages: storages
        )
    }
}

extension ProxmoxNode {
    fileprivate init?(resource: ClusterResource.Payload) {
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
    fileprivate init?(resource: ClusterResource.Payload, kind: GuestKind) {
        guard let vmid = resource.vmid, let node = resource.node, !node.isEmpty else { return nil }
        let status: GuestStatus =
            if kind == .virtualMachine && resource.lock == "suspended" {
                .suspendedToDisk
            } else {
                GuestStatus(rawValue: resource.status ?? "unknown")
            }

        self.init(
            id: resource.id,
            vmid: vmid,
            kind: kind,
            node: node,
            name: resource.name,
            status: status,
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
    fileprivate init(resource: ClusterResource.Payload) {
        self.init(
            id: resource.id,
            name: resource.storage ?? resource.name ?? resource.id,
            node: resource.node,
            availability: .init(status: resource.status),
            used: resource.disk,
            total: resource.maxdisk,
            content: resource.contentList,
            pluginType: resource.plugintype,
            isShared: resource.shared?.value ?? false
        )
    }
}
