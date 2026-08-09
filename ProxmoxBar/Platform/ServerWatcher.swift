import AppKit
import Foundation
import Observation

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
        guard gate?.isEnabled ?? true else {
            previousGuests.removeAll()
            previousNodes.removeAll()
            return
        }

        let servers = store.servers
        let living = Set(servers.map(\.id))
        previousGuests = previousGuests.filter { living.contains($0.key) }
        previousNodes = previousNodes.filter { living.contains($0.key) }

        await withTaskGroup(of: (UUID, ClusterState?).self) { group in
            for server in servers {
                let id = server.id
                group.addTask { [weak self] in
                    guard let self else { return (id, nil) }
                    return (id, await self.fetch(id))
                }
            }
            for await (id, state) in group {
                if let state { handle(server: id, state: state) }
            }
        }
    }

    private func fetch(_ id: UUID) async -> ClusterState? {
        guard let server = try? store.server(for: id) else { return nil }
        return try? await api.clusterState(of: server)
    }

    private func handle(server id: UUID, state: ClusterState) {
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
