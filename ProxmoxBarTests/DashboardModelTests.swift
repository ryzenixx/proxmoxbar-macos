import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Dashboard selection")
@MainActor
struct DashboardModelTests {
    private func makeStore(names: [String]) throws -> ServerStore {
        let defaults = try #require(UserDefaults(suiteName: "Dashboard.\(UUID().uuidString)"))
        let store = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        for name in names {
            try store.add(
                ServerConfiguration(
                    name: name,
                    address: "https://192.168.1.1:8006",
                    tokenIdentifier: "monitor@pve!bar"
                ),
                secret: "s"
            )
        }
        return store
    }

    @Test("The first server is selected on opening")
    func selectsFirstServer() throws {
        let store = try makeStore(names: ["Alpha", "Beta"])
        let model = DashboardModel(store: store)
        #expect(model.selected?.name == "Alpha")
    }

    @Test("Selecting another server switches to it")
    func selectsAnotherServer() throws {
        let store = try makeStore(names: ["Alpha", "Beta"])
        let model = DashboardModel(store: store)
        let beta = try #require(store.servers.first { $0.name == "Beta" })
        model.select(beta.id)
        #expect(model.selected?.name == "Beta")
    }

    @Test("Selecting a server that is not in the list is ignored")
    func ignoresUnknownSelection() throws {
        let store = try makeStore(names: ["Alpha"])
        let model = DashboardModel(store: store)
        model.select(UUID())
        #expect(model.selected?.name == "Alpha")
    }

    @Test("Removing the selected server falls back to the first one")
    func fallsBackWhenSelectionDisappears() throws {
        let store = try makeStore(names: ["Alpha", "Beta"])
        let model = DashboardModel(store: store)
        let beta = try #require(store.servers.first { $0.name == "Beta" })
        model.select(beta.id)

        try store.remove(beta.id)
        model.selectionDidChange()
        #expect(model.selected?.name == "Alpha")
    }

    @Test("Removing the last server leaves nothing selected")
    func nothingSelectedWhenEmptied() throws {
        let store = try makeStore(names: ["Alpha"])
        let model = DashboardModel(store: store)
        try store.remove(try #require(store.servers.first).id)
        model.selectionDidChange()
        #expect(model.selected == nil)
    }

    @Test("A failing refresh keeps the last values and flags them as stale")
    func keepsLastValuesWhenRefreshFails() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)

        let loaded = ClusterState(
            nodes: [], guests: [], storages: [], discardedCount: 0
        )
        api.returns(loaded)
        await model.refresh()
        #expect(model.phase == .loaded(loaded))
        #expect(model.isStale == false)

        api.fails(with: ProxmoxError.timedOut)
        await model.refresh()
        #expect(model.phase == .loaded(loaded))
        #expect(model.isStale)
    }

    @Test("A first refresh that fails has nothing to keep and reports the error")
    func reportsFailureWithNothingLoaded() async throws {
        let api = StubProxmoxAPI()
        api.fails(with: ProxmoxError.unauthorized)
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)

        await model.refresh()
        guard case .failed = model.phase else {
            Issue.record("Expected a failed phase, got \(model.phase)")
            return
        }
        #expect(model.isStale == false)
    }

    @Test("Monitoring keeps polling on its own until it is stopped")
    func monitoringPollsRepeatedly() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(
            store: try makeStore(names: ["Alpha"]),
            api: api,
            refreshInterval: .milliseconds(20)
        )

        model.startMonitoring()
        try await Task.sleep(for: .milliseconds(300))
        model.stopMonitoring()
        let polled = api.callCount
        #expect(polled >= 3)

        try await Task.sleep(for: .milliseconds(150))
        #expect(api.callCount == polled)
    }

    @Test("Recovering clears the stale flag and stamps the refresh")
    func recoveryClearsStaleness() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)

        await model.refresh()
        api.fails(with: ProxmoxError.timedOut)
        await model.refresh()
        #expect(model.isStale)

        api.returns(.empty)
        await model.refresh()
        #expect(model.isStale == false)
        #expect(model.lastRefresh != nil)
    }
}
