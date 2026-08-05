import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Server store")
@MainActor
struct ServerStoreTests {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "ProxmoxBarTests.\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: suite))
    }

    private func makeConfiguration(name: String = "Homelab") -> ServerConfiguration {
        ServerConfiguration(
            name: name,
            address: "https://192.168.1.1:8006",
            tokenIdentifier: "monitor@pve!bar"
        )
    }

    @Test("A fresh install starts empty")
    func startsEmpty() throws {
        let store = ServerStore(defaults: try makeDefaults(), secrets: InMemorySecretStore())
        #expect(store.servers.isEmpty)
        #expect(store.state == .empty)
    }

    @Test("A server survives a reload, and its secret never reaches the defaults")
    func persistsAcrossReload() throws {
        let defaults = try makeDefaults()
        let secrets = InMemorySecretStore()
        let store = ServerStore(defaults: defaults, secrets: secrets)
        let configuration = makeConfiguration()
        try store.add(configuration, secret: "top-secret")

        let reloaded = ServerStore(defaults: defaults, secrets: secrets)
        #expect(reloaded.servers.count == 1)
        #expect(reloaded.servers.first?.name == "Homelab")
        #expect(reloaded.state == .loaded)

        let raw = try #require(defaults.data(forKey: ServerStore.storageKey))
        let text = try #require(String(data: raw, encoding: .utf8))
        #expect(text.contains("top-secret") == false)
    }

    @Test("Removing a server also removes its secret")
    func removalTakesTheSecret() throws {
        let secrets = InMemorySecretStore()
        let store = ServerStore(defaults: try makeDefaults(), secrets: secrets)
        let configuration = makeConfiguration()
        try store.add(configuration, secret: "top-secret")
        #expect(secrets.count == 1)

        try store.remove(configuration.id)
        #expect(store.servers.isEmpty)
        #expect(secrets.count == 0)
    }

    @Test("Accepting a certificate pins its fingerprint on that server")
    func trustPinsFingerprint() throws {
        let store = ServerStore(defaults: try makeDefaults(), secrets: InMemorySecretStore())
        let configuration = makeConfiguration()
        try store.add(configuration, secret: "s")
        #expect(store.servers.first?.pinnedFingerprint == nil)

        store.trust("65:D3:EB", for: configuration.id)
        #expect(store.servers.first?.pinnedFingerprint == "65:D3:EB")
        let server = try #require(try store.server(for: configuration.id))
        #expect(server.pinnedFingerprint == "65:D3:EB")
    }

    @Test("A server whose secret is missing is still listed, and flagged")
    func serverWithoutSecretStaysListed() throws {
        let defaults = try makeDefaults()
        let store = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        let configuration = makeConfiguration()
        try store.add(configuration, secret: "s")

        let reloaded = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        #expect(reloaded.servers.count == 1)
        #expect(reloaded.needsToken(configuration.id))
        #expect(try reloaded.server(for: configuration.id) == nil)
    }

    @Test("A payload from a newer version is reported, never overwritten")
    func refusesToClobberANewerSchema() throws {
        let defaults = try makeDefaults()
        let future = #"{"schemaVersion":99,"servers":[]}"#
        defaults.set(Data(future.utf8), forKey: ServerStore.storageKey)

        let store = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        #expect(store.state == .unreadable(schemaVersion: 99))

        let raw = try #require(defaults.data(forKey: ServerStore.storageKey))
        #expect(String(data: raw, encoding: .utf8) == future)
    }

    @Test("A stored configuration rebuilds a usable server")
    func rebuildsServerFromStorage() throws {
        let store = ServerStore(defaults: try makeDefaults(), secrets: InMemorySecretStore())
        let configuration = makeConfiguration()
        try store.add(configuration, secret: "a-secret")

        let server = try #require(try store.server(for: configuration.id))
        #expect(server.credentials.authorizationHeader == "PVEAPIToken=monitor@pve!bar=a-secret")
    }
}
