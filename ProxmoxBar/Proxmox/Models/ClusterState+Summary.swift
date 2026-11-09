import Foundation

extension ClusterState {
    var onlineNodes: Int {
        nodes.filter(\.isOnline).count
    }

    var runningGuests: Int {
        guests.filter { $0.status.isRunning }.count
    }

    var totalCores: Int {
        Int(nodes.compactMap(\.maxCPUs).reduce(0, +))
    }

    var cpuUsage: Double? {
        let cores = nodes.compactMap(\.maxCPUs).reduce(0, +)
        guard cores > 0 else { return nil }
        let used = nodes.reduce(0.0) { total, node in
            total + (node.cpu ?? 0) * (node.maxCPUs ?? 0)
        }
        return min(used / cores, 1)
    }

    var memory: ClusterCapacity? {
        let total = nodes.compactMap(\.maximumMemory).reduce(0, +)
        guard total > 0 else { return nil }
        return ClusterCapacity(used: nodes.compactMap(\.memory).reduce(0, +), total: total)
    }

    var storage: ClusterCapacity? {
        var used = 0
        var total = 0

        for storage in distinctStorages where storage.isAvailable {
            guard let capacity = storage.total, capacity > 0, let occupied = storage.used else {
                continue
            }
            used += occupied
            total += capacity
        }

        guard total > 0 else { return nil }
        return ClusterCapacity(used: used, total: total)
    }

    var distinctStorages: [ProxmoxStorage] {
        let ordered = storages.sorted { lhs, rhs in
            if lhs.isAvailable != rhs.isAvailable { return lhs.isAvailable }
            let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return (lhs.usage ?? -1) > (rhs.usage ?? -1)
        }

        var seenShared: Set<String> = []
        return ordered.filter { !$0.isShared || seenShared.insert($0.name).inserted }
    }
}
