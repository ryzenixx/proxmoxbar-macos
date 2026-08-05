import Foundation
import Observation
import os

@MainActor
@Observable
final class ServerStore {
    enum LoadState: Hashable, Sendable {
        case loaded
        case empty
        case unreadable(schemaVersion: Int)
    }

    static let storageKey = "ProxmoxBar.servers"

    private(set) var servers: [ServerConfiguration] = []
    private(set) var state: LoadState = .empty

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
        try secrets.store(secret, for: configuration.id)
        servers.append(configuration)
        persist()
    }

    func update(_ configuration: ServerConfiguration) {
        guard let index = servers.firstIndex(where: { $0.id == configuration.id }) else { return }
        servers[index] = configuration
        persist()
    }

    func remove(_ identifier: UUID) throws {
        servers.removeAll { $0.id == identifier }
        persist()
        try secrets.removeSecret(for: identifier)
    }

    func trust(_ fingerprint: String, for identifier: UUID) {
        guard let index = servers.firstIndex(where: { $0.id == identifier }) else { return }
        servers[index].pinnedFingerprint = fingerprint
        persist()
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
        ((try? secrets.secret(for: identifier)) ?? nil) == nil
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey) else {
            state = .empty
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
            state = .unreadable(schemaVersion: -1)
            logger.error("Stored servers could not be decoded: \(error.localizedDescription)")
        }
    }

    private func persist() {
        guard state != .unreadable(schemaVersion: -1) else { return }
        do {
            let data = try JSONEncoder().encode(StoredServers(servers: servers))
            defaults.set(data, forKey: Self.storageKey)
            state = servers.isEmpty ? .empty : .loaded
        } catch {
            logger.error("Servers could not be saved: \(error.localizedDescription)")
        }
    }
}
