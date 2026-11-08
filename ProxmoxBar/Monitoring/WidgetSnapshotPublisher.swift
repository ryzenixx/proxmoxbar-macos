import WidgetKit

@MainActor
struct WidgetSnapshotPublisher {
    private var lastSignature: String?

    mutating func publish(
        servers: [ServerConfiguration], readings: [ServerConfiguration: ServerWatcher.Reading]
    ) {
        let snapshots = servers.map { snapshot(for: $0, reading: readings[$0]) }
        WidgetSharedStore.write(snapshots)
        let signature = snapshots.map(\.signature).joined(separator: "|")
        if signature != lastSignature {
            lastSignature = signature
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func snapshot(
        for config: ServerConfiguration, reading: ServerWatcher.Reading?
    ) -> WidgetSnapshot {
        let state = reading?.state
        return WidgetSnapshot(
            id: config.id.uuidString,
            name: config.name,
            reachable: state != nil,
            observedAt: reading?.observedAt,
            nodesOnline: state?.onlineNodes ?? 0,
            nodesTotal: state?.nodes.count ?? 0,
            running: state?.runningGuests ?? 0,
            guestsTotal: state?.guests.count ?? 0,
            cpu: state?.cpuUsage,
            memory: state?.memory?.ratio,
            storage: state?.storage?.ratio
        )
    }
}

extension WidgetSnapshot {
    fileprivate var signature: String {
        "\(id)-\(name)-\(observedAt != nil)-\(reachable)-\(nodesOnline)/\(nodesTotal)-\(running)/\(guestsTotal)"
    }
}
