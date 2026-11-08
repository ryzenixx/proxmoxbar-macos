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

    private enum Phase: Equatable {
        case idle
        case loading
        case loaded(ClusterState)
        case failed(String)
    }

    private struct ConfirmedStatus {
        let status: GuestStatus
        let confirmedAt: Date
    }

    private struct ActionKey: Hashable {
        let source: Source
        let guestID: String
    }

    static let confirmedStatusLifetime: TimeInterval = 60

    private var selectedID: UUID?
    private var phase: Phase = .idle
    private var displaySource: Source?
    private var refreshFailure: String?
    private var runningActions: [ActionKey: GuestAction] = [:]
    private(set) var actionFailures: [String: String] = [:]
    private var confirmedStatuses: [String: ConfirmedStatus] = [:]
    private var demoID: UUID?

    var isDemo: Bool { demoID != nil }

    var failureMessage: String? {
        guard displaySource == activeSource else { return nil }
        if let refreshFailure { return refreshFailure }
        if case .failed(let message) = phase { return message }
        return nil
    }

    var visibleSnapshot: Snapshot? {
        guard let displaySource, displaySource == activeSource, case .loaded(let state) = phase
        else { return nil }
        let visible = state.applying(confirmedStatuses.mapValues(\.status))
        return Snapshot(source: displaySource, state: visible)
    }

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let recorder: any UserActionRecorder
    @ObservationIgnored private let polling = PollingSchedule()
    @ObservationIgnored private var refreshGeneration = 0

    init(store: ServerStore, api: any ProxmoxAPI, recorder: any UserActionRecorder) {
        self.store = store
        self.api = api
        self.recorder = recorder
    }

    var servers: [ServerConfiguration] {
        store.servers
    }

    var selected: ServerConfiguration? {
        if let selected = servers.first(where: { $0.id == selectedID }) {
            return selected
        }
        return servers.first
    }

    private var activeSource: Source? {
        if let demoID { return .demo(demoID) }
        return selected.map { .server(id: $0.id, address: $0.address) }
    }

    func startMonitoring() {
        polling.start { [weak self] in
            await self?.refresh()
        }
    }

    func stopMonitoring() {
        polling.stop()
    }

    func select(_ identifier: UUID) {
        guard identifier != selected?.id,
            servers.contains(where: { $0.id == identifier })
        else { return }
        selectedID = identifier
        reloadSelection()
    }

    func selectionDidChange() {
        if let selectedID, !servers.contains(where: { $0.id == selectedID }) {
            self.selectedID = nil
        }
        if displaySource != activeSource { reloadSelection() }
    }

    private func reloadSelection() {
        resetDisplay(to: activeSource)
        Task { await refresh() }
    }

    private func resetDisplay(to source: Source?) {
        refreshGeneration += 1
        phase = .idle
        refreshFailure = nil
        actionFailures.removeAll()
        confirmedStatuses.removeAll()
        displaySource = source
    }

    func enterDemo() {
        stopMonitoring()
        demoID = UUID()
        selectedID = nil
        resetDisplay(to: activeSource)
        phase = .loaded(DemoCluster.state())
    }

    func exitDemo() {
        demoID = nil
        resetDisplay(to: activeSource)
    }

    private func performDemo(_ action: GuestAction, on guest: ProxmoxGuest, from source: Source)
        async
    {
        try? await Task.sleep(for: .seconds(0.8))
        guard isDisplaying(source), case .loaded(let current) = phase,
            let settled = action.settledStatus
        else { return }
        phase = .loaded(current.applying([guest.id: settled]))
    }

    func runningAction(for guest: ProxmoxGuest, from source: Source) -> GuestAction? {
        runningActions[ActionKey(source: source, guestID: guest.id)]
    }

    private func isDisplaying(_ source: Source) -> Bool {
        displaySource == source && activeSource == source
    }

    func perform(_ action: GuestAction, on guest: ProxmoxGuest, from source: Source) async {
        guard isDisplaying(source), case .loaded = phase else { return }
        let key = ActionKey(source: source, guestID: guest.id)
        guard runningActions[key] == nil else { return }
        runningActions[key] = action
        defer { runningActions[key] = nil }

        guard case .server(let target, _) = source else {
            await performDemo(action, on: guest, from: source)
            return
        }
        actionFailures[guest.id] = nil
        recorder.recordUserAction(server: target, guestID: guest.id)

        do {
            guard let server = try store.server(for: target) else {
                actionFailures[guest.id] = "This server has no token yet."
                return
            }
            try await api.perform(action, on: guest, of: server)
            guard isDisplaying(source) else { return }
            if let settled = action.settledStatus {
                confirmedStatuses[guest.id] = ConfirmedStatus(
                    status: settled,
                    confirmedAt: Date()
                )
            }
        } catch is CancellationError {
            return
        } catch {
            guard isDisplaying(source) else { return }
            actionFailures[guest.id] =
                (error as? ProxmoxError)?.errorDescription ?? error.localizedDescription
        }
        await refresh()
    }

    private func reconcileConfirmedStatuses(against state: ClusterState) {
        guard !confirmedStatuses.isEmpty else { return }
        let now = Date()
        for (id, confirmed) in confirmedStatuses {
            let reported = state.guests.first { $0.id == id }?.status
            let agreed = reported == confirmed.status
            let expired =
                now.timeIntervalSince(confirmed.confirmedAt) > Self.confirmedStatusLifetime
            if agreed || expired || reported == nil {
                confirmedStatuses[id] = nil
            }
        }
    }

    func dismissFailure(for guest: ProxmoxGuest, from source: Source) {
        guard isDisplaying(source) else { return }
        actionFailures[guest.id] = nil
    }

    func refresh() async {
        if isDemo { return }
        let source = activeSource
        if displaySource != source { resetDisplay(to: source) }
        guard let source, case .server(let target, _) = source else { return }
        if phase == .idle {
            phase = .loading
        }
        refreshGeneration += 1
        let generation = refreshGeneration
        do {
            guard let server = try store.server(for: target) else {
                phase = .failed("This server has no token yet.")
                return
            }
            let state = try await api.clusterState(of: server)
            guard generation == refreshGeneration, isDisplaying(source) else { return }
            reconcileConfirmedStatuses(against: state)
            phase = .loaded(state)
            refreshFailure = nil
        } catch is CancellationError {
            return
        } catch {
            guard generation == refreshGeneration, isDisplaying(source) else { return }
            let message =
                (error as? ProxmoxError)?.errorDescription ?? error.localizedDescription
            if case .loaded = phase {
                refreshFailure = message
            } else {
                phase = .failed(message)
            }
        }
    }
}
