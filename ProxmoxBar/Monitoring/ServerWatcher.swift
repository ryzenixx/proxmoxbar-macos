import Foundation

@MainActor
protocol UserActionRecorder {
    func recordUserAction(server: UUID, guestID: String)
}

@MainActor
final class ServerWatcher: UserActionRecorder {
    static let actionWindow: TimeInterval = 90

    private let store: ServerStore
    private let api: any ProxmoxAPI
    private let notifier: any StatusChangeNotifier
    private let polling = PollingSchedule()

    private var previousGuests: [UUID: [String: GuestStatus]] = [:]
    private var previousNodes: [UUID: [String: Bool]] = [:]
    private var recentActions: [String: Date] = [:]
    private var widgetPublisher = WidgetSnapshotPublisher()

    init(store: ServerStore, api: any ProxmoxAPI, notifier: any StatusChangeNotifier) {
        self.store = store
        self.api = api
        self.notifier = notifier
    }

    func start() {
        polling.start { [weak self] in
            await self?.pollOnce()
        }
    }

    func stop() {
        polling.stop()
    }

    func recordUserAction(server: UUID, guestID: String) {
        recentActions[key(server, guestID)] = Date()
    }

    private func pollOnce() async {
        pruneRecentActions()

        let servers = store.servers
        let living = Set(servers.map(\.id))
        previousGuests = previousGuests.filter { living.contains($0.key) }
        previousNodes = previousNodes.filter { living.contains($0.key) }

        let targets = servers.compactMap { config in
            (try? store.server(for: config.id)).map { (config.id, $0) }
        }

        let api = self.api
        var states: [UUID: ClusterState] = [:]
        await withTaskGroup(of: (UUID, ClusterState?).self) { group in
            for (id, server) in targets {
                group.addTask {
                    (id, try? await api.clusterState(of: server))
                }
            }
            for await (id, state) in group {
                if let state { states[id] = state }
            }
        }

        widgetPublisher.publish(servers: servers, states: states)

        let shouldNotify = notifier.isEnabled
        for (id, state) in states {
            handle(server: id, state: state, notify: shouldNotify)
        }
    }

    private func pruneRecentActions() {
        let now = Date()
        recentActions = recentActions.filter {
            now.timeIntervalSince($0.value) <= Self.actionWindow
        }
    }

    private func handle(server id: UUID, state: ClusterState, notify: Bool) {
        if notify {
            let skip = Set(state.guests.map(\.id).filter { recentlyActed(id, $0) })
            for change in GuestStatusChange.detect(
                previous: previousGuests[id] ?? [:],
                current: state.guests,
                skipping: skip
            ) {
                notifier.post(change.event)
            }
            for change in NodeStatusChange.detect(
                previous: previousNodes[id] ?? [:],
                current: state.nodes
            ) {
                notifier.post(change.event)
            }
        }
        previousGuests[id] = Dictionary(
            uniqueKeysWithValues: state.guests.map { ($0.id, $0.status) }
        )
        previousNodes[id] = Dictionary(
            uniqueKeysWithValues: state.nodes.map { ($0.name, $0.isOnline) }
        )
    }

    private func recentlyActed(_ server: UUID, _ guestID: String) -> Bool {
        guard let at = recentActions[key(server, guestID)] else { return false }
        if Date().timeIntervalSince(at) > Self.actionWindow {
            recentActions[key(server, guestID)] = nil
            return false
        }
        return true
    }

    private func key(_ server: UUID, _ guestID: String) -> String {
        "\(server.uuidString)/\(guestID)"
    }
}
