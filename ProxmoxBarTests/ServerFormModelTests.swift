import Foundation
import Testing

@testable import ProxmoxBar

private struct StubAPI: ProxmoxAPI {
    var onVersion: @Sendable (ProxmoxServer) async throws -> ServerVersion

    func version(of server: ProxmoxServer) async throws -> ServerVersion {
        try await onVersion(server)
    }

    func clusterState(of server: ProxmoxServer) async throws -> ClusterState {
        .empty
    }

    func perform(
        _ action: GuestAction,
        on guest: ProxmoxGuest,
        of server: ProxmoxServer
    ) async throws {}
}

private let certificate = ServerCertificate(
    fingerprint: "65:D3:EB",
    subject: "pve.lan",
    issuer: "PVE Cluster Manager CA",
    notBefore: nil,
    expiry: nil
)

@Suite("Server form")
@MainActor
struct ServerFormModelTests {
    private func makeStore() throws -> ServerStore {
        let defaults = try #require(UserDefaults(suiteName: "AddServer.\(UUID().uuidString)"))
        return ServerStore(defaults: defaults, secrets: InMemorySecretStore())
    }

    private func makeModel(
        store: ServerStore,
        onVersion: @escaping @Sendable (ProxmoxServer) async throws -> ServerVersion
    ) -> ServerFormModel {
        let model = ServerFormModel(api: StubAPI(onVersion: onVersion), store: store)
        model.address = "https://192.168.1.1:8006"
        model.tokenIdentifier = "monitor@pve!bar"
        model.secret = "a-secret"
        return model
    }

    @Test("An empty form cannot be submitted")
    func emptyFormIsNotSubmittable() throws {
        let model = ServerFormModel(
            api: StubAPI { _ in ServerVersion(version: "9", release: "9", repositoryID: "x") },
            store: try makeStore()
        )
        #expect(model.canSubmit == false)
    }

    @Test("An address without a scheme is refused before any request")
    func schemelessAddressIsRefused() throws {
        let model = makeModel(store: try makeStore()) { _ in
            Issue.record("No request should be made")
            return ServerVersion(version: "9", release: "9", repositoryID: "x")
        }
        model.address = "192.168.1.1:8006"
        #expect(model.canSubmit == false)
    }

    @Test("A reachable server is saved with its token")
    func savesReachableServer() async throws {
        let store = try makeStore()
        let model = makeModel(store: store) { _ in
            ServerVersion(version: "9.2.2", release: "9.2", repositoryID: "abc")
        }
        await model.connect()

        #expect(model.phase == .saved)
        #expect(store.servers.count == 1)
        #expect(store.servers.first?.name == "192.168.1.1")
        let stored = try #require(store.servers.first)
        let saved = try #require(try store.server(for: stored.id))
        #expect(saved.credentials.secret == "a-secret")
    }

    @Test("A given name wins over the host")
    func keepsTheGivenName() async throws {
        let store = try makeStore()
        let model = makeModel(store: store) { _ in
            ServerVersion(version: "9", release: "9", repositoryID: "x")
        }
        model.name = "Homelab"
        await model.connect()
        #expect(store.servers.first?.name == "Homelab")
    }

    @Test("A rejected token is reported and nothing is saved")
    func reportsRejectedToken() async throws {
        let store = try makeStore()
        let model = makeModel(store: store) { _ in throw ProxmoxError.unauthorized }
        await model.connect()

        #expect(model.phase == .failed(ProxmoxError.unauthorized.localizedDescription))
        #expect(store.servers.isEmpty)
    }

    @Test("An untrusted certificate asks before saving anything")
    func asksBeforeTrusting() async throws {
        let store = try makeStore()
        let model = makeModel(store: store) { _ in
            throw ProxmoxError.untrustedCertificate(certificate, problems: [.untrustedIssuer])
        }
        await model.connect()

        #expect(model.phase == .awaitingTrust(certificate, [.untrustedIssuer]))
        #expect(store.servers.isEmpty)
    }

    @Test("Accepting the certificate retries and pins the fingerprint")
    func acceptingPinsAndSaves() async throws {
        let store = try makeStore()
        let attempts = Attempts()
        let model = ServerFormModel(
            api: StubAPI { server in
                if await attempts.next() == 1 {
                    throw ProxmoxError.untrustedCertificate(
                        certificate,
                        problems: [.untrustedIssuer]
                    )
                }
                #expect(server.pinnedFingerprint == "65:D3:EB")
                return ServerVersion(version: "9", release: "9", repositoryID: "x")
            },
            store: store
        )
        model.address = "https://192.168.1.1:8006"
        model.tokenIdentifier = "monitor@pve!bar"
        model.secret = "a-secret"

        await model.connect()
        await model.trustPresentedCertificate()

        #expect(model.phase == .saved)
        #expect(store.servers.first?.pinnedFingerprint == "65:D3:EB")
    }

    @Test("Refusing the certificate leaves the form untouched")
    func refusingKeepsEditing() async throws {
        let store = try makeStore()
        let model = makeModel(store: store) { _ in
            throw ProxmoxError.untrustedCertificate(certificate, problems: [.untrustedIssuer])
        }
        await model.connect()
        model.cancelTrust()

        #expect(model.phase == .editing)
        #expect(store.servers.isEmpty)
    }
}

private actor Attempts {
    private var count = 0

    func next() -> Int {
        count += 1
        return count
    }
}

@Suite("Editing a server")
@MainActor
struct EditServerFormTests {
    private func makeStore() throws -> (ServerStore, ServerConfiguration) {
        let defaults = try #require(UserDefaults(suiteName: "EditServer.\(UUID().uuidString)"))
        let store = ServerStore(defaults: defaults, secrets: InMemorySecretStore())
        let configuration = ServerConfiguration(
            name: "Homelab",
            address: "https://192.168.1.1:8006",
            tokenIdentifier: "monitor@pve!bar",
            pinnedFingerprint: "65:D3:EB"
        )
        try store.add(configuration, secret: "original-secret")
        return (store, configuration)
    }

    private func makeModel(
        store: ServerStore,
        configuration: ServerConfiguration
    ) -> ServerFormModel {
        ServerFormModel(
            mode: .editing(configuration),
            api: StubAPI { _ in ServerVersion(version: "9", release: "9", repositoryID: "x") },
            store: store
        )
    }

    @Test("The form opens already filled with what was stored")
    func fillsFromExistingServer() throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)

        #expect(model.name == "Homelab")
        #expect(model.address == "https://192.168.1.1:8006")
        #expect(model.tokenIdentifier == "monitor@pve!bar")
        #expect(model.secret.isEmpty)
        #expect(model.isEditing)
    }

    @Test("A blank secret keeps the one already in the keychain")
    func blankSecretKeepsTheStoredOne() async throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)
        model.name = "Renamed"

        #expect(model.keepsExistingSecret)
        #expect(model.canSubmit)
        await model.connect()

        #expect(model.phase == .saved)
        #expect(store.servers.count == 1)
        #expect(store.servers.first?.name == "Renamed")
        #expect(store.servers.first?.id == configuration.id)
        #expect(try store.secret(for: configuration.id) == "original-secret")
    }

    @Test("A typed secret replaces the stored one")
    func typedSecretReplacesTheStoredOne() async throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)
        model.secret = "rotated-secret"

        await model.connect()

        #expect(model.phase == .saved)
        #expect(try store.secret(for: configuration.id) == "rotated-secret")
    }

    @Test("Moving a server to another address drops the certificate pinned to the old one")
    func changingAddressDropsThePin() async throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)
        model.address = "https://192.168.1.2:8006"

        await model.connect()

        #expect(model.phase == .saved)
        #expect(store.servers.first?.address == "https://192.168.1.2:8006")
        #expect(store.servers.first?.pinnedFingerprint == nil)
    }

    @Test("Keeping the same address keeps the certificate that was already trusted")
    func sameAddressKeepsThePin() async throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)
        model.name = "Still Homelab"

        await model.connect()

        #expect(store.servers.first?.pinnedFingerprint == "65:D3:EB")
    }

    @Test("Editing never creates a second server")
    func editingDoesNotDuplicate() async throws {
        let (store, configuration) = try makeStore()
        let model = makeModel(store: store, configuration: configuration)
        model.tokenIdentifier = "other@pve!token"

        await model.connect()

        #expect(store.servers.count == 1)
        #expect(store.servers.first?.tokenIdentifier == "other@pve!token")
    }
}
