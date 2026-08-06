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

    static let defaultRefreshInterval = Duration.seconds(5)

    private(set) var selectedID: UUID?
    private(set) var phase: Phase = .idle
    private(set) var lastRefresh: Date?
    private(set) var isStale = false

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI
    @ObservationIgnored private let refreshInterval: Duration
    @ObservationIgnored private var monitor: Task<Void, Never>?
    @ObservationIgnored private var wakeObserver: (any NSObjectProtocol)?

    init(
        store: ServerStore,
        api: any ProxmoxAPI = ProxmoxAPIClient(),
        refreshInterval: Duration = DashboardModel.defaultRefreshInterval
    ) {
        self.store = store
        self.api = api
        self.refreshInterval = refreshInterval
        selectedID = store.servers.first?.id
    }

    deinit {
        monitor?.cancel()
    }

    var servers: [ServerConfiguration] {
        store.servers
    }

    var selected: ServerConfiguration? {
        guard let selectedID else { return nil }
        return store.servers.first { $0.id == selectedID }
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
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        wakeObserver = nil
    }

    func select(_ identifier: UUID) {
        guard identifier != selectedID,
            store.servers.contains(where: { $0.id == identifier })
        else { return }
        selectedID = identifier
        phase = .idle
        isStale = false
        lastRefresh = nil
        Task { await refresh() }
    }

    func selectionDidChange() {
        guard !store.servers.contains(where: { $0.id == selectedID }) else { return }
        selectedID = store.servers.first?.id
        phase = .idle
        isStale = false
        lastRefresh = nil
        Task { await refresh() }
    }

    func refresh() async {
        guard let target = selectedID else {
            phase = .idle
            return
        }
        if phase == .idle {
            phase = .loading
        }
        do {
            guard let server = try store.server(for: target) else {
                phase = .failed("This server has no token yet.")
                return
            }
            let state = try await api.clusterState(of: server)
            guard target == selectedID else { return }
            phase = .loaded(state)
            lastRefresh = Date()
            isStale = false
        } catch is CancellationError {
            return
        } catch {
            guard target == selectedID else { return }
            let message =
                (error as? ProxmoxError)?.errorDescription ?? error.localizedDescription
            if case .loaded = phase {
                isStale = true
            } else {
                phase = .failed(message)
            }
        }
    }
}
