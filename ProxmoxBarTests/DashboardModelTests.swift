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
        #expect(model.hasSeveralServers)
    }

    @Test("A single server is not offered as a choice")
    func singleServerIsNotAChoice() throws {
        let model = DashboardModel(store: try makeStore(names: ["Alpha"]))
        #expect(model.hasSeveralServers == false)
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
}
