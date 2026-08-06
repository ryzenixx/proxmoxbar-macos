import Foundation
import Observation

@MainActor
@Observable
final class DashboardModel {
    private(set) var selectedID: UUID?

    @ObservationIgnored private let store: ServerStore

    init(store: ServerStore) {
        self.store = store
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
        guard store.servers.contains(where: { $0.id == identifier }) else { return }
        selectedID = identifier
    }

    func selectionDidChange() {
        guard let selectedID, store.servers.contains(where: { $0.id == selectedID }) else {
            self.selectedID = store.servers.first?.id
            return
        }
    }
}
