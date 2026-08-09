import AppKit
import Foundation
import Observation
import WidgetKit

@MainActor
protocol UserActionRecorder {
    func recordUserAction(server: UUID, guestID: String)
}

struct NoopActionRecorder: UserActionRecorder {
    func recordUserAction(server: UUID, guestID: String) {}
}

@MainActor
protocol NotificationSwitch: AnyObject {
    var isEnabled: Bool { get }
}

@MainActor
final class ServerWatcher: UserActionRecorder {
    static let defaultInterval = Duration.seconds(5)
    static let actionWindow: TimeInterval = 90

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let notifier: any StatusChangeNotifier
    @ObservationIgnored private weak var gate: (any NotificationSwitch)?
    @ObservationIgnored private let interval: Duration

    private var loop: Task<Void, Never>?
    private var wakeWatcher: Task<Void, Never>?
    private var previousGuests: [UUID: [String: GuestStatus]] = [:]
    private var previousNodes: [UUID: [String: Bool]] = [:]
    private var recentActions: [String: Date] = [:]
    private var lastWidgetSignature: String?

    init(
        store: ServerStore,
        api: any ProxmoxAPI = ProxmoxAPIClient(),
        notifier: any StatusChangeNotifier = SilentNotifier(),
        gate: (any NotificationSwitch)? = nil,
        interval: Duration = ServerWatcher.defaultInterval
    ) {
        self.store = store
        self.api = api
        self.notifier = notifier
        self.gate = gate
        self.interval = interval
    }

    deinit {
        loop?.cancel()
        wakeWatcher?.cancel()
    }

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                guard let interval = self?.interval else { return }
                try? await Task.sleep(for: interval)
            }
        }
        wakeWatcher = Task { [weak self] in
            let wakes = NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.didWakeNotification
            )
            for await _ in wakes {
                await self?.pollOnce()
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
        wakeWatcher?.cancel()
        wakeWatcher = nil
    }

    func recordUserAction(server: UUID, guestID: String) {
        recentActions[key(server, guestID)] = Date()
    }

    func pollOnce() async {
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

        publishWidgets(servers: servers, states: states)

        let shouldNotify = gate?.isEnabled ?? true
        for (id, state) in states {
            handle(server: id, state: state, notify: shouldNotify)
        }
    }

    private func publishWidgets(servers: [ServerConfiguration], states: [UUID: ClusterState]) {
        let snapshots = servers.map { snapshot(for: $0, state: states[$0.id]) }
        WidgetSharedStore.write(snapshots)
        let signature = snapshots.map(\.signature).joined(separator: "|")
        if signature != lastWidgetSignature {
            lastWidgetSignature = signature
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
