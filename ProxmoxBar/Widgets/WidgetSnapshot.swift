import Foundation

enum WidgetSharedStore {
    static let appGroup = "DL58RM98AN.group.com.proxmoxbar.app"
    private static let key = "widget.snapshots"

    static func write(_ snapshots: [WidgetSnapshot]) {
        guard let defaults = UserDefaults(suiteName: appGroup),
            let data = try? JSONEncoder().encode(snapshots)
        else { return }
        defaults.set(data, forKey: key)
    }

    static func read() -> [WidgetSnapshot] {
        guard let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: key),
            let snapshots = try? JSONDecoder().decode([WidgetSnapshot].self, from: data)
        else { return [] }
        return snapshots
    }
}

struct WidgetSnapshot: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let reachable: Bool
    let nodesOnline: Int
    let nodesTotal: Int
    let running: Int
    let guestsTotal: Int
    let cpu: Double?
    let memory: Double?
    let storage: Double?

    var signature: String {
        "\(reachable)-\(nodesOnline)/\(nodesTotal)-\(running)/\(guestsTotal)"
    }
}
