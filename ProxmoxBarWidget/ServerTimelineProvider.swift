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
        let entry = ServerEntry(date: .now, snapshot: resolve(configuration))
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func resolve(_ configuration: SelectServerIntent) -> WidgetSnapshot? {
        let all = WidgetSharedStore.read()
        if let id = configuration.server?.id, let match = all.first(where: { $0.id == id }) {
            return match
        }
        return all.first
    }
}

struct ServerEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

extension WidgetSnapshot {
    static let placeholder = WidgetSnapshot(
        id: "placeholder",
        name: "homelab",
        reachable: true,
        nodesOnline: 1,
        nodesTotal: 1,
        running: 8,
        guestsTotal: 12,
        cpu: 0.27,
        memory: 0.12,
        storage: 0.34
    )
}
