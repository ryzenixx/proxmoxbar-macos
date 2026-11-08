import Foundation
import WidgetKit

struct ServerTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ServerEntry {
        ServerEntry(date: .now, snapshot: .placeholder)
    }

    func snapshot(for configuration: SelectServerIntent, in context: Context) async -> ServerEntry {
        ServerEntry(date: .now, snapshot: resolve(configuration))
    }

    func timeline(for configuration: SelectServerIntent, in context: Context) async
        -> Timeline<ServerEntry>
    {
        let now = Date.now
        let snapshot = resolve(configuration)
        var entries = [ServerEntry(date: now, snapshot: snapshot)]
        if let snapshot, let staleAt = snapshot.staleAt, !snapshot.isStale(at: now) {
            entries.append(ServerEntry(date: staleAt, snapshot: snapshot))
        }
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60)))
    }

    private func resolve(_ configuration: SelectServerIntent) -> WidgetSnapshot? {
        let all = WidgetSharedStore.read()
        if let id = configuration.server?.id {
            return all.first { $0.id == id }
        }
        return all.first
    }
}

struct ServerEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

extension WidgetSnapshot {
    static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            id: "placeholder",
            name: "homelab",
            reachable: true,
            observedAt: .now,
            nodesOnline: 1,
            nodesTotal: 1,
            running: 8,
            guestsTotal: 12,
            cpu: 0.27,
            memory: 0.12,
            storage: 0.34
        )
    }
}
