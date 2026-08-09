import Foundation
import Testing

@testable import ProxmoxBar

@MainActor
private final class RecordingNotifier: StatusChangeNotifier {
    private(set) var posted: [StatusEvent] = []
    func post(_ event: StatusEvent) { posted.append(event) }
}

@MainActor
private final class Gate: NotificationSwitch {
    var isEnabled: Bool
    init(_ isEnabled: Bool) { self.isEnabled = isEnabled }
}

@Suite("Server watcher")
@MainActor
struct ServerWatcherTests {
    private func makeStore(_ names: [String]) throws -> ServerStore {
        let defaults = try #require(UserDefaults(suiteName: "Watcher.\(UUID().uuidString)"))
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

    private func state(_ status: String) throws -> ClusterState {
        let json = """
            [{"id":"qemu/1","type":"qemu","vmid":1,"node":"a","status":"\(status)"}]
            """
        let data = try #require(json.data(using: .utf8))
        return ClusterState(resources: try JSONDecoder().decode([ClusterResource].self, from: data))
    }

    @Test("The first sweep is a silent baseline, the next change speaks")
    func firstSweepIsSilent() async throws {
        let api = StubProxmoxAPI()
        let notifier = RecordingNotifier()
        let gate = Gate(true)
        let watcher = ServerWatcher(
            store: try makeStore(["Alpha"]), api: api, notifier: notifier, gate: gate
        )

        api.returns(try state("running"))
        await watcher.pollOnce()
        #expect(notifier.posted.isEmpty)

        api.returns(try state("stopped"))
        await watcher.pollOnce()
        #expect(notifier.posted.count == 1)
        #expect(notifier.posted.first?.body.contains("stopped") == true)
    }

    @Test("A change is announced once for every server that reports it")
    func announcesPerServer() async throws {
        let api = StubProxmoxAPI()
        let notifier = RecordingNotifier()
        let gate = Gate(true)
        let watcher = ServerWatcher(
            store: try makeStore(["Alpha", "Beta"]), api: api, notifier: notifier, gate: gate
        )

        api.returns(try state("running"))
        await watcher.pollOnce()

        api.returns(try state("stopped"))
        await watcher.pollOnce()
        #expect(notifier.posted.count == 2)
    }

    @Test("A guest the user just acted on stays quiet on its server")
    func suppressesRecordedActions() async throws {
        let api = StubProxmoxAPI()
        let notifier = RecordingNotifier()
        let store = try makeStore(["Alpha"])
        let gate = Gate(true)
        let watcher = ServerWatcher(
            store: store, api: api, notifier: notifier, gate: gate
        )
        let server = try #require(store.servers.first)
        let guest = try #require((try state("running")).guests.first)

        api.returns(try state("running"))
        await watcher.pollOnce()

        watcher.recordUserAction(server: server.id, guestID: guest.id)
        api.returns(try state("stopped"))
        await watcher.pollOnce()
        #expect(notifier.posted.isEmpty)
    }

    @Test("Nothing is announced while notifications are switched off")
    func staysSilentWhenDisabled() async throws {
        let api = StubProxmoxAPI()
        let notifier = RecordingNotifier()
        let gate = Gate(false)
        let watcher = ServerWatcher(
            store: try makeStore(["Alpha"]), api: api, notifier: notifier, gate: gate
        )

        api.returns(try state("running"))
        await watcher.pollOnce()
        api.returns(try state("stopped"))
        await watcher.pollOnce()
        #expect(notifier.posted.isEmpty)
    }
}
