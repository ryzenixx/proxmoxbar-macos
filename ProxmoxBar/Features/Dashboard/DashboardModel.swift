import Foundation
import Observation

@MainActor
@Observable
final class DashboardModel {
    enum Source: Hashable {
        case server(id: UUID, address: String)
        case demo(UUID)
    }

    struct Snapshot {
        let source: Source
        let state: ClusterState
    }

    enum ActionProgress: Equatable {
        case executing(GuestAction)
        case confirmingState

        var label: String {
            switch self {
            case .executing(let action): action.progressLabel
            case .confirmingState: "Checking machine state…"
            }
        }
    }

    enum ActionNotice: Equatable {
        case failed(String)
        case taskUnconfirmed
        case taskWarnings(Int)
        case stateUnconfirmed

        var message: String {
            switch self {
            case .failed(let message): message
            case .taskUnconfirmed: ProxmoxError.taskStatusUnconfirmed.localizedDescription
            case .taskWarnings(let count):
                count == 1
                    ? "The task completed with one warning in Proxmox."
                    : "The task completed with \(count) warnings in Proxmox."
            case .stateUnconfirmed:
                "The task completed, but the machine’s new state could not be confirmed."
            }
        }
    }

    private struct ActionKey: Hashable {
        let source: Source
        let guestID: String
    }

    private var selectedID: UUID?
    private var displaySource: Source?
    private var runningActions: [ActionKey: ActionProgress] = [:]
    private var notices: [String: ActionNotice] = [:]
    private var demoID: UUID?
    private var demoState: ClusterState?

    var isDemo: Bool { demoID != nil }

    var failureMessage: String? { currentReading?.failureMessage }

    var actionNotices: [String: ActionNotice] {
        displaySource == activeSource ? notices : [:]
    }

    var visibleSnapshot: Snapshot? {
        guard let source = activeSource, let state = isDemo ? demoState : currentReading?.state
        else { return nil }
        return Snapshot(source: source, state: state)
    }

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let watcher: ServerWatcher

    init(store: ServerStore, api: any ProxmoxAPI, watcher: ServerWatcher) {
        self.store = store
        self.api = api
        self.watcher = watcher
    }

    var servers: [ServerConfiguration] { store.servers }

    var selected: ServerConfiguration? {
        servers.first { $0.id == selectedID } ?? servers.first
    }

    private var activeSource: Source? {
        if let demoID { return .demo(demoID) }
        return selected.map { .server(id: $0.id, address: $0.address) }
    }

    private var currentReading: ServerWatcher.Reading? {
        guard !isDemo, let selected else { return nil }
        return watcher.reading(for: selected)
    }

    func select(_ identifier: UUID) {
        guard identifier != selected?.id, servers.contains(where: { $0.id == identifier })
        else { return }
        selectedID = identifier
        selectionDidChange()
    }

    func selectionDidChange() {
        if let selectedID, !servers.contains(where: { $0.id == selectedID }) {
            self.selectedID = nil
        }
        updateDisplaySource()
        Task { await loadSelection() }
    }

    private func updateDisplaySource() {
        let source = activeSource
        guard displaySource != source else { return }
        notices.removeAll()
        displaySource = source
    }

    func loadSelection() async {
        updateDisplaySource()
        guard !isDemo, let selected, watcher.reading(for: selected) == nil else { return }
        await watcher.refresh(selected)
    }

    func refresh() async {
        guard !isDemo, let selected else { return }
        await watcher.refresh(selected)
    }

    func enterDemo() {
        demoID = UUID()
        demoState = DemoCluster.state()
        selectedID = nil
        updateDisplaySource()
    }

    func exitDemo() {
        demoID = nil
        demoState = nil
        updateDisplaySource()
    }

    private func performDemo(_ action: GuestAction, on guest: ProxmoxGuest, from source: Source)
        async
    {
        try? await Task.sleep(for: .seconds(0.8))
        guard isDisplaying(source), let demoState, let settled = action.settledStatus else {
            return
        }
        self.demoState = demoState.applying([guest.id: settled])
    }

    func actionProgress(for guest: ProxmoxGuest, from source: Source) -> ActionProgress? {
        runningActions[ActionKey(source: source, guestID: guest.id)]
    }

    private func isDisplaying(_ source: Source) -> Bool {
        displaySource == source && activeSource == source
    }

    func perform(_ action: GuestAction, on guest: ProxmoxGuest, from source: Source) async {
        guard isDisplaying(source), visibleSnapshot?.source == source else { return }
        let key = ActionKey(source: source, guestID: guest.id)
        guard runningActions[key] == nil else { return }
        runningActions[key] = .executing(action)
        defer { runningActions[key] = nil }

        guard case .server(let target, _) = source, let configuration = selected else {
            await performDemo(action, on: guest, from: source)
            return
        }
        notices[guest.id] = nil

        do {
            guard let server = try store.server(for: target) else {
                notices[guest.id] = .failed("This server has no token yet.")
                return
            }
            let cluster = try await api.clusterState(of: server)
            guard !Task.isCancelled, isDisplaying(source), selected == configuration else {
                return
            }
            guard
                let currentGuest = cluster.guests.first(where: {
                    $0.id == guest.id && $0.vmid == guest.vmid && $0.kind == guest.kind
                })
            else {
                notices[guest.id] = .failed("This machine is no longer visible on this server.")
                await watcher.refresh(configuration)
                return
            }
            guard currentGuest.availableActions.contains(action) else {
                notices[guest.id] = .failed("This action is no longer available for this machine.")
                await watcher.refresh(configuration)
                return
            }
            watcher.recordUserAction(server: target, guestID: guest.id)
            let completion = try await api.perform(action, on: currentGuest, of: server)
            let completedAt = ContinuousClock.now
            watcher.recordUserAction(server: target, guestID: guest.id)
            guard isDisplaying(source), selected == configuration else { return }

            let confirmed: Bool
            if let expected = action.settledStatus {
                runningActions[key] = .confirmingState
                await watcher.refresh(configuration)
                let timeout: Duration = currentGuest.haState == nil ? .seconds(20) : .seconds(90)
                confirmed = try await confirm(
                    expected, for: key, since: completedAt, timeout: timeout, on: configuration
                )
            } else {
                await watcher.refresh(configuration)
                confirmed = true
            }
            guard isDisplaying(source), selected == configuration else { return }
            if !confirmed {
                notices[guest.id] = .stateUnconfirmed
            } else if case .warnings(let count) = completion {
                notices[guest.id] = .taskWarnings(count)
            }
        } catch is CancellationError {
            return
        } catch {
            guard isDisplaying(source), selected == configuration else { return }
            notices[guest.id] =
                if case ProxmoxError.taskStatusUnconfirmed = error {
                    .taskUnconfirmed
                } else {
                    .failed(error.localizedDescription)
                }
            await watcher.refresh(configuration)
        }
    }

    private func confirm(
        _ expected: GuestStatus,
        for key: ActionKey,
        since completedAt: ContinuousClock.Instant,
        timeout: Duration,
        on configuration: ServerConfiguration
    ) async throws -> Bool {
        let deadline = completedAt.advanced(by: timeout)
        while isDisplaying(key.source), selected == configuration {
            if let reading = watcher.reading(for: configuration),
                reading.startedAt >= completedAt,
                reading.state?.guests.first(where: { $0.id == key.guestID })?.status == expected
            {
                return true
            }
            guard ContinuousClock.now < deadline else { break }
            try await Task.sleep(for: .seconds(1))
        }
        return false
    }

    func dismissNotice(for guest: ProxmoxGuest, from source: Source) {
        guard isDisplaying(source) else { return }
        notices[guest.id] = nil
    }
}
