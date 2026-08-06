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

    @Test("A failing refresh keeps the last values and records why it failed")
    func keepsLastValuesWhenRefreshFails() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)

        let loaded = ClusterState(
            nodes: [], guests: [], storages: [], discardedCount: 0
        )
        api.returns(loaded)
        await model.refresh()
        #expect(model.phase == .loaded(loaded))
        #expect(model.refreshFailure == nil)

        api.fails(with: ProxmoxError.timedOut)
        await model.refresh()
        #expect(model.phase == .loaded(loaded))
        #expect(model.refreshFailure != nil)
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
        #expect(model.refreshFailure == nil)
    }

    private func resources(status: String) throws -> [ClusterResource] {
        let json = """
            [{"id":"qemu/1","type":"qemu","vmid":1,"node":"a","status":"\(status)"}]
            """
        let data = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode([ClusterResource].self, from: data)
    }

    private func runningResources() throws -> [ClusterResource] {
        try resources(status: "running")
    }

    private func stoppedResources() throws -> [ClusterResource] {
        try resources(status: "stopped")
    }

    private func runningGuest() throws -> ProxmoxGuest {
        try #require(ClusterState(resources: try runningResources()).guests.first)
    }

    @Test("A power action is sent and the cluster is read back right after")
    func performsActionThenRefreshes() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)
        let guest = try runningGuest()

        await model.perform(.shutdown, on: guest)

        #expect(api.performedActions == [.shutdown])
        #expect(api.callCount == 1)
        #expect(model.runningActions.isEmpty)
        #expect(model.actionFailures.isEmpty)
    }

    @Test("A failing power action is reported against its own machine")
    func reportsActionFailure() async throws {
        let api = StubProxmoxAPI()
        api.failsActions(with: ProxmoxError.forbidden)
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)
        let guest = try runningGuest()

        await model.perform(.stop, on: guest)

        #expect(model.actionFailures[guest.id] != nil)
        #expect(model.runningActions.isEmpty)

        model.dismissFailure(for: guest)
        #expect(model.actionFailures[guest.id] == nil)
    }

    @Test("A confirmed state is shown while the cached cluster view still lags")
    func showsConfirmedStateWhileClusterLags() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)
        let guest = try runningGuest()
        api.returns(ClusterState(resources: try runningResources()))

        await model.perform(.shutdown, on: guest)

        let shown = try #require(model.visibleState?.guests.first)
        #expect(shown.status == .stopped)
        #expect(model.confirmedStatuses[guest.id] != nil)
    }

    @Test("The confirmation is dropped once the cluster agrees on its own")
    func dropsConfirmationOnceClusterAgrees() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)
        let guest = try runningGuest()
        api.returns(ClusterState(resources: try runningResources()))
        await model.perform(.shutdown, on: guest)
        #expect(model.confirmedStatuses[guest.id] != nil)

        api.returns(ClusterState(resources: try stoppedResources()))
        await model.refresh()

        #expect(model.confirmedStatuses.isEmpty)
        #expect(model.visibleState?.guests.first?.status == .stopped)
    }

    @Test("Switching servers drops every trace of the previous one")
    func switchingServersClearsPerGuestState() async throws {
        let api = StubProxmoxAPI()
        let store = try makeStore(names: ["Alpha", "Beta"])
        let model = DashboardModel(store: store, api: api)
        let guest = try runningGuest()
        api.returns(ClusterState(resources: try runningResources()))

        api.failsActions(with: ProxmoxError.forbidden)
        await model.perform(.stop, on: guest)
        #expect(model.actionFailures.isEmpty == false)

        let beta = try #require(store.servers.first { $0.name == "Beta" })
        model.select(beta.id)

        #expect(model.actionFailures.isEmpty)
        #expect(model.confirmedStatuses.isEmpty)
        #expect(model.runningActions.isEmpty)
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

    @Test("Recovering clears the failure and stamps the refresh")
    func recoveryClearsTheFailure() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]), api: api)

        await model.refresh()
        api.fails(with: ProxmoxError.timedOut)
        await model.refresh()
        #expect(model.refreshFailure != nil)

        api.returns(.empty)
        await model.refresh()
        #expect(model.refreshFailure == nil)
    }
}

@Suite("Dashboard failures")
@MainActor
struct DashboardFailureTests {
    private func makeStore() throws -> ServerStore {
        let defaults = try #require(UserDefaults(suiteName: "Failure.\(UUID().uuidString)"))
        let store = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        try store.add(
            ServerConfiguration(
                name: "Alpha",
                address: "https://192.168.1.1:8006",
                tokenIdentifier: "monitor@pve!bar"
            ),
            secret: "s"
        )
        return store
    }

    @Test("A first failure surfaces its message")
    func firstFailureSurfaces() async throws {
        let api = StubProxmoxAPI()
        api.fails(with: ProxmoxError.unauthorized)
        let model = DashboardModel(store: try makeStore(), api: api)

        await model.refresh()

        #expect(model.failureMessage == "The API token was rejected.")
        #expect(model.visibleState == nil)
    }

    @Test("A failure after a good read reports why, and the stale values stay out of sight")
    func laterFailureHidesStaleValues() async throws {
        let api = StubProxmoxAPI()
        let model = DashboardModel(store: try makeStore(), api: api)
        await model.refresh()
        #expect(model.failureMessage == nil)

        api.fails(with: ProxmoxError.timedOut)
        await model.refresh()

        #expect(model.failureMessage == "The server did not answer in time.")
    }

    @Test("Retrying successfully clears the failure")
    func retryClearsFailure() async throws {
        let api = StubProxmoxAPI()
        api.fails(with: ProxmoxError.timedOut)
        let model = DashboardModel(store: try makeStore(), api: api)
        await model.refresh()
        #expect(model.failureMessage != nil)

        api.returns(.empty)
        await model.refresh()

        #expect(model.failureMessage == nil)
        #expect(model.visibleState != nil)
    }
}
