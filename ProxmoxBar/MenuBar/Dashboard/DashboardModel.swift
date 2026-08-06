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

    private(set) var selectedID: UUID?
    private(set) var phase: Phase = .idle

    @ObservationIgnored private let store: ServerStore
    @ObservationIgnored private let api: any ProxmoxAPI

    init(store: ServerStore, api: any ProxmoxAPI = ProxmoxAPIClient()) {
        self.store = store
        self.api = api
        selectedID = store.servers.first?.id
    }

    var servers: [ServerConfiguration] {
        store.servers
    }

    var selected: ServerConfiguration? {
        guard let selectedID else { return nil }
        return store.servers.first { $0.id == selectedID }
    }

    var hasSeveralServers: Bool {
        store.servers.count > 1
    }

    func select(_ identifier: UUID) {
        guard identifier != selectedID,
            store.servers.contains(where: { $0.id == identifier })
        else { return }
        selectedID = identifier
        phase = .idle
    }

    func selectionDidChange() {
        guard let selectedID, store.servers.contains(where: { $0.id == selectedID }) else {
            self.selectedID = store.servers.first?.id
            phase = .idle
            return
        }
    }

    func refresh() async {
        guard let selectedID else {
            phase = .idle
            return
        }
        if phase == .idle {
            phase = .loading
        }
        do {
            guard let server = try store.server(for: selectedID) else {
                phase = .failed("This server has no token yet.")
                return
            }
            phase = .loaded(try await api.clusterState(of: server))
        } catch is CancellationError {
            return
        } catch let error as ProxmoxError {
            phase = .failed(error.errorDescription ?? "The cluster could not be read.")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
