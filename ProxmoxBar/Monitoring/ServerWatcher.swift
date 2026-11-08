import Foundation
import Observation

@MainActor
@Observable
final class ServerWatcher {
    struct Reading {
        let result: Result<ClusterState, ProxmoxError>
        let startedAt: ContinuousClock.Instant
        let observedAt: Date

        var state: ClusterState? { try? result.get() }

        var failureMessage: String? {
            if case .failure(let error) = result { return error.localizedDescription }
            return nil
        }
    }

    static let actionWindow: TimeInterval = 90

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let notifier: any StatusChangeNotifier
    @ObservationIgnored private let polling = PollingSchedule()

    private var readings: [ServerConfiguration: Reading] = [:]
    @ObservationIgnored private var requests: [ServerConfiguration: Task<Void, Never>] = [:]
    @ObservationIgnored private var isPolling = false
    @ObservationIgnored private var previousGuests: [ServerConfiguration: [String: GuestStatus]] =
        [:]
    @ObservationIgnored private var previousNodes: [ServerConfiguration: [String: Bool]] = [:]
    @ObservationIgnored private var recentActions: [String: Date] = [:]
    @ObservationIgnored private var widgetPublisher = WidgetSnapshotPublisher()

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
        for request in requests.values { request.cancel() }
    }

    func recordUserAction(server: UUID, guestID: String) {
        recentActions[key(server, guestID)] = Date()
    }

    func reading(for configuration: ServerConfiguration) -> Reading? {
        readings[configuration]
    }

    func refresh(_ configuration: ServerConfiguration) async {
        guard !Task.isCancelled, store.servers.contains(configuration) else { return }
        if let request = requests[configuration] {
            await request.value
            return
        }

        let request = Task<Void, Never> { [weak self] in
            await self?.fetch(configuration)
        }
        requests[configuration] = request
        await request.value
    }

    private func fetch(_ configuration: ServerConfiguration) async {
        defer { requests[configuration] = nil }
        guard !Task.isCancelled, store.servers.contains(configuration) else { return }

        let startedAt = ContinuousClock.now
        let result: Result<ClusterState, ProxmoxError>
        do {
            guard let server = try store.server(for: configuration.id) else {
                throw ProxmoxError.transport("This server has no token yet.")
            }
            result = .success(try await api.clusterState(of: server))
        } catch is CancellationError {
            return
        } catch {
            result = .failure((error as? ProxmoxError) ?? .transport(error.localizedDescription))
        }

        guard !Task.isCancelled, store.servers.contains(configuration) else { return }
        readings[configuration] = Reading(result: result, startedAt: startedAt, observedAt: .now)
        if case .success(let state) = result {
            handle(server: configuration, state: state, notify: notifier.isEnabled)
        }
    }

    private func pollOnce() async {
        guard !Task.isCancelled, !isPolling else { return }
        isPolling = true
        defer { isPolling = false }
        pruneRecentActions()

        let servers = store.servers
        let living = Set(servers)
        if readings.keys.contains(where: { !living.contains($0) }) {
            readings = readings.filter { living.contains($0.key) }
        }
        previousGuests = previousGuests.filter { living.contains($0.key) }
        previousNodes = previousNodes.filter { living.contains($0.key) }

        await withTaskGroup(of: Void.self) { group in
            for configuration in servers {
                group.addTask { await self.refresh(configuration) }
            }
        }

        guard !Task.isCancelled, store.writeError == nil else { return }
        widgetPublisher.publish(servers: store.servers, readings: readings)
    }

    private func pruneRecentActions() {
        let now = Date()
        recentActions = recentActions.filter {
            now.timeIntervalSince($0.value) <= Self.actionWindow
        }
    }

    private func handle(server: ServerConfiguration, state: ClusterState, notify: Bool) {
        if notify {
            let skip = Set(state.guests.map(\.id).filter { recentlyActed(server.id, $0) })
            for change in GuestStatusChange.detect(
                previous: previousGuests[server] ?? [:],
                current: state.guests,
                skipping: skip
            ) {
                notifier.post(change.event)
            }
            for change in NodeStatusChange.detect(
                previous: previousNodes[server] ?? [:],
                current: state.nodes
            ) {
                notifier.post(change.event)
            }
        }
        previousGuests[server] = Dictionary(
            uniqueKeysWithValues: state.guests.map { ($0.id, $0.status) }
        )
        previousNodes[server] = Dictionary(
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
