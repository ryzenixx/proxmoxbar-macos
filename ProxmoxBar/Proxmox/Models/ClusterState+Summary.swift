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
        var countedShared: Set<String> = []
        var used = 0
        var total = 0

        for storage in storages where !storage.isUnavailable {
            guard let capacity = storage.total, capacity > 0 else { continue }
            if storage.isShared, !countedShared.insert(storage.name).inserted { continue }
            used += storage.used ?? 0
            total += capacity
        }

        guard total > 0 else { return nil }
        return ClusterCapacity(used: used, total: total)
    }

    var distinctStorages: [ProxmoxStorage] {
        var seenShared: Set<String> = []
        var result: [ProxmoxStorage] = []

        for storage in storages {
            if storage.isShared, !seenShared.insert(storage.name).inserted { continue }
            result.append(storage)
        }

        return result.sorted { lhs, rhs in
            if lhs.isUnavailable != rhs.isUnavailable { return rhs.isUnavailable }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
