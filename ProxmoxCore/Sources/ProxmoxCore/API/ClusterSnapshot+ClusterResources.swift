import Foundation

extension ClusterSnapshot {
    init(_ resources: [ClusterResource]) {
        self.init(
            nodes: resources.compactMap(ProxmoxNode.init),
            storages: resources.compactMap(ProxmoxStorage.init).sorted(by: ProxmoxStorage.byUsageThenName),
            guests: resources.compactMap(ProxmoxGuest.init).sorted { $0.vmid < $1.vmid },
            pools: resources.compactMap(ProxmoxPool.init),
            sdnZones: resources.compactMap(ProxmoxSDNZone.init),
            networks: resources.compactMap(ProxmoxNetwork.init)
        )
    }
}

extension String {
    var proxmoxList: [String] {
        split(whereSeparator: { $0 == ";" || $0 == "," || $0 == " " })
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

private extension ProxmoxNode {
    init?(_ resource: ClusterResource) {
        guard resource.type == "node", let node = resource.node else { return nil }

        self.init(
            node: node,
            status: resource.status ?? "unknown",
            cpu: resource.cpu,
            maxcpu: resource.maxcpu,
            mem: resource.mem,
            maxmem: resource.maxmem,
            disk: resource.disk,
            maxdisk: resource.maxdisk,
            uptime: resource.uptime,
            supportLevel: resource.level,
            hostArchitecture: resource.hostArchitecture,
            cgroupMode: resource.cgroupMode
        )
    }
}

private extension ProxmoxStorage {
    init?(_ resource: ClusterResource) {
        guard resource.type == "storage",
              let storage = resource.storage,
              let node = resource.node else {
            return nil
        }

        self.init(
            storage: storage,
            node: node,
            status: resource.status ?? "unknown",
            disk: resource.disk,
            maxdisk: resource.maxdisk,
            pluginType: resource.plugintype,
            contentTypes: resource.content?.proxmoxList ?? [],
            isShared: resource.shared?.value ?? false
        )
    }

    static func byUsageThenName(_ lhs: ProxmoxStorage, _ rhs: ProxmoxStorage) -> Bool {
        if lhs.diskUsage != rhs.diskUsage {
            return lhs.diskUsage > rhs.diskUsage
        }
        return lhs.storage < rhs.storage
    }
}

private extension ProxmoxGuest {
    init?(_ resource: ClusterResource) {
        guard ["qemu", "lxc", "openvz"].contains(resource.type),
              let vmid = resource.vmid,
              let node = resource.node else {
            return nil
        }

        self.init(
            vmid: vmid,
            name: resource.name,
            status: resource.status ?? "unknown",
            type: resource.type,
            node: node,
            pool: resource.pool,
            tags: resource.tags?.proxmoxList ?? [],
            isTemplate: resource.template?.value ?? false,
            lock: resource.lock,
            haState: resource.hastate,
            cpu: resource.cpu,
            maxcpu: resource.maxcpu,
            mem: resource.mem,
            maxmem: resource.maxmem,
            hostMemory: resource.memhost,
            disk: resource.disk,
            maxdisk: resource.maxdisk,
            uptime: resource.uptime,
            networkIn: resource.netin,
            networkOut: resource.netout,
            diskRead: resource.diskread,
            diskWritten: resource.diskwrite
        )
    }
}

private extension ProxmoxPool {
    init?(_ resource: ClusterResource) {
        guard resource.type == "pool", let pool = resource.pool ?? resource.id.poolIdentifier else {
            return nil
        }
        self.init(pool: pool)
    }
}

private extension ProxmoxSDNZone {
    init?(_ resource: ClusterResource) {
        guard resource.type == "sdn", let sdn = resource.sdn else { return nil }

        self.init(
            sdn: sdn,
            node: resource.node,
            status: resource.status,
            zoneType: resource.zoneType
        )
    }
}

private extension ProxmoxNetwork {
    init?(_ resource: ClusterResource) {
        guard resource.type == "network", let network = resource.network else { return nil }

        self.init(
            network: network,
            node: resource.node,
            status: resource.status,
            networkType: resource.networkType,
            networkProtocol: resource.netProtocol
        )
    }
}

private extension String {
    var poolIdentifier: String? {
        guard hasPrefix("/pool/") else { return nil }
        let name = dropFirst("/pool/".count)
        return name.isEmpty ? nil : String(name)
    }
}
