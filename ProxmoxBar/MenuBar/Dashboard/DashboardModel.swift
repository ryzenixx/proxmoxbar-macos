import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class DashboardModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded(ClusterState)
        case failed(String)
    }

    struct ConfirmedStatus: Hashable, Sendable {
        let status: GuestStatus
        let confirmedAt: Date
    }

    static let defaultRefreshInterval = Duration.seconds(5)
    static let confirmedStatusLifetime: TimeInterval = 60

    private(set) var selectedID: UUID?
    private(set) var phase: Phase = .idle
    private(set) var refreshFailure: String?
    private(set) var runningActions: [String: GuestAction] = [:]
    private(set) var actionFailures: [String: String] = [:]
    private(set) var confirmedStatuses: [String: ConfirmedStatus] = [:]

    var failureMessage: String? {
        if let refreshFailure { return refreshFailure }
        if case .failed(let message) = phase { return message }
        return nil
    }

    var visibleState: ClusterState? {
        guard case .loaded(let state) = phase else { return nil }
        guard !confirmedStatuses.isEmpty else { return state }
        return state.applying(confirmedStatuses.mapValues(\.status))
    }

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let recorder: any UserActionRecorder
    @ObservationIgnored private let refreshInterval: Duration
    @ObservationIgnored private var monitor: Task<Void, Never>?
    @ObservationIgnored private var wakeWatcher: Task<Void, Never>?
    @ObservationIgnored private var refreshGeneration = 0

    init(
        store: ServerStore,
        api: any ProxmoxAPI = ProxmoxAPIClient(),
        recorder: any UserActionRecorder = NoopActionRecorder(),
        refreshInterval: Duration = DashboardModel.defaultRefreshInterval
    ) {
        self.store = store
        self.api = api
        self.recorder = recorder
        self.refreshInterval = refreshInterval
    }

    deinit {
        monitor?.cancel()
        wakeWatcher?.cancel()
    }

    var servers: [ServerConfiguration] {
        store.servers
    }

    var activeID: UUID? {
        if let selectedID, store.servers.contains(where: { $0.id == selectedID }) {
            return selectedID
        }
        return store.servers.first?.id
    }

    var selected: ServerConfiguration? {
        guard let activeID else { return nil }
        return store.servers.first { $0.id == activeID }
    }

    func startMonitoring() {
        guard monitor == nil else { return }
        monitor = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                guard let interval = self?.refreshInterval else { return }
                try? await Task.sleep(for: interval)
            }
        }
        wakeWatcher = Task { [weak self] in
            let wakes = NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.didWakeNotification
            )
            for await _ in wakes {
                await self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        wakeWatcher?.cancel()
        wakeWatcher = nil
    }

    func select(_ identifier: UUID) {
        guard identifier != activeID,
            store.servers.contains(where: { $0.id == identifier })
        else { return }
        startOver(on: identifier)
    }

    func selectionDidChange() {
        guard let selectedID, !store.servers.contains(where: { $0.id == selectedID }) else {
            return
        }
        startOver(on: nil)
    }

    private func startOver(on identifier: UUID?) {
        selectedID = identifier
        phase = .idle
        refreshFailure = nil
        runningActions.removeAll()
        actionFailures.removeAll()
        confirmedStatuses.removeAll()
        Task { await refresh() }
    }

    func perform(_ action: GuestAction, on guest: ProxmoxGuest) async {
        guard let target = activeID, runningActions[guest.id] == nil else { return }
        runningActions[guest.id] = action
        actionFailures[guest.id] = nil
        recorder.recordUserAction(server: target, guestID: guest.id)
        defer { runningActions[guest.id] = nil }

        do {
            guard let server = try store.server(for: target) else {
                actionFailures[guest.id] = "This server has no token yet."
                return
            }
            try await api.perform(action, on: guest, of: server)
            guard target == activeID else { return }
            if let settled = action.settledStatus {
                confirmedStatuses[guest.id] = ConfirmedStatus(
                    status: settled,
                    confirmedAt: Date()
                )
            }
        } catch is CancellationError {
            return
        } catch {
            guard target == activeID else { return }
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

    func dismissFailure(for guest: ProxmoxGuest) {
        actionFailures[guest.id] = nil
    }

    func refresh() async {
        guard let target = activeID else {
            phase = .idle
            return
        }
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
            guard generation == refreshGeneration, target == activeID else { return }
            reconcileConfirmedStatuses(against: state)
            phase = .loaded(state)
            refreshFailure = nil
        } catch is CancellationError {
            return
        } catch {
            guard generation == refreshGeneration, target == activeID else { return }
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
