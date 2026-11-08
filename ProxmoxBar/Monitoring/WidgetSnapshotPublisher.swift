import WidgetKit

@MainActor
struct WidgetSnapshotPublisher {
    private var lastSignature: String?

    mutating func publish(servers: [ServerConfiguration], states: [UUID: ClusterState]) {
        let snapshots = servers.map { snapshot(for: $0, state: states[$0.id]) }
        WidgetSharedStore.write(snapshots)
        let signature = snapshots.map(\.signature).joined(separator: "|")
        if signature != lastSignature {
            lastSignature = signature
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func snapshot(for config: ServerConfiguration, state: ClusterState?) -> WidgetSnapshot {
        guard let state else {
            return WidgetSnapshot(
                id: config.id.uuidString,
                name: config.name,
                reachable: false,
                nodesOnline: 0,
                nodesTotal: 0,
                running: 0,
                guestsTotal: 0,
                cpu: nil,
                memory: nil,
                storage: nil
            )
        }
        return WidgetSnapshot(
            id: config.id.uuidString,
            name: config.name,
            reachable: true,
            nodesOnline: state.onlineNodes,
            nodesTotal: state.nodes.count,
            running: state.runningGuests,
            guestsTotal: state.guests.count,
            cpu: state.cpuUsage,
            memory: state.memory?.ratio,
            storage: state.storage?.ratio
        )
    }
}

extension WidgetSnapshot {
    fileprivate var signature: String {
        "\(reachable)-\(nodesOnline)/\(nodesTotal)-\(running)/\(guestsTotal)"
    }
}
