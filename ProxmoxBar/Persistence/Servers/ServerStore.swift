import Foundation
import Observation
import os

@MainActor
@Observable
final class ServerStore {
    enum LoadState: Hashable, Sendable {
        case loaded
        case empty
        case unreadable(schemaVersion: Int?)
    }

    enum WriteError: LocalizedError {
        case unreadableStorage(schemaVersion: Int?)
        case serverChanged

        var errorDescription: String? {
            switch self {
            case .unreadableStorage(.some):
                "A newer version of ProxmoxBar saved these servers. Open that version to make changes."
            case .unreadableStorage(.none):
                "The saved servers could not be read. Changes are disabled to protect them."
            case .serverChanged:
                "This server changed while you were editing it. Reopen it and try again."
            }
        }
    }

    static let storageKey = "ProxmoxBar.servers"

    private(set) var servers: [ServerConfiguration] = []
    private(set) var state: LoadState = .empty

    var writeError: WriteError? {
        guard case .unreadable(let schemaVersion) = state else { return nil }
        return .unreadableStorage(schemaVersion: schemaVersion)
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let secrets: any SecretStore
    @ObservationIgnored private let logger = Logger(
        subsystem: "com.proxmoxbar.app",
        category: "storage"
    )

    init(defaults: UserDefaults = .standard, secrets: any SecretStore = KeychainSecretStore()) {
        self.defaults = defaults
        self.secrets = secrets
        load()
    }

    func add(_ configuration: ServerConfiguration, secret: String) throws {
        let updated = servers + [configuration]
        let data = try prepareWrite(updated)
        try secrets.store(secret, for: configuration.id)
        persist(updated, data: data)
    }

    func update(_ configuration: ServerConfiguration, secret: String? = nil) throws {
        guard let index = servers.firstIndex(where: { $0.id == configuration.id }) else {
            throw writeError ?? WriteError.serverChanged
        }
        var updated = servers
        updated[index] = configuration
        let data = try prepareWrite(updated)
        if let secret {
            try secrets.store(secret, for: configuration.id)
        }
        persist(updated, data: data)
    }

    func remove(_ identifier: UUID) throws {
        let updated = servers.filter { $0.id != identifier }
        let data = try prepareWrite(updated)
        try secrets.removeSecret(for: identifier)
        persist(updated, data: data)
    }

    func secret(for identifier: UUID) throws -> String? {
        try secrets.secret(for: identifier)
    }

    func server(for identifier: UUID) throws -> ProxmoxServer? {
        guard let configuration = servers.first(where: { $0.id == identifier }),
            let secret = try secrets.secret(for: identifier)
        else { return nil }
        return configuration.server(withSecret: secret)
    }

    func needsToken(_ identifier: UUID) -> Bool {
        (try? secret(for: identifier)) == nil
    }

    private func load() {
        guard let value = defaults.object(forKey: Self.storageKey) else {
            state = .empty
            return
        }
        guard let data = value as? Data else {
            state = .unreadable(schemaVersion: nil)
            logger.error("Stored servers were not saved as data.")
            return
        }
        do {
            let stored = try JSONDecoder().decode(StoredServers.self, from: data)
            guard stored.isReadable else {
                state = .unreadable(schemaVersion: stored.schemaVersion)
                logger.error("Stored servers use schema \(stored.schemaVersion), which is newer.")
                return
            }
            servers = stored.servers
            state = .loaded
        } catch {
            state = .unreadable(schemaVersion: nil)
            logger.error("Stored servers could not be decoded: \(error.localizedDescription)")
        }
    }

    private func prepareWrite(_ updated: [ServerConfiguration]) throws -> Data {
        if let writeError { throw writeError }
        return try JSONEncoder().encode(StoredServers(servers: updated))
    }

    private func persist(_ updated: [ServerConfiguration], data: Data) {
        defaults.set(data, forKey: Self.storageKey)
        servers = updated
        state = updated.isEmpty ? .empty : .loaded
    }
}
