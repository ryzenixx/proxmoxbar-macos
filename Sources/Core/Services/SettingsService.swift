import Foundation
import Combine
import SwiftUI

enum SettingsSheet: Identifiable {
    case add
    case edit(ProxmoxServerConfig)
    
    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let server): return server.id.uuidString
        }
    }
}

struct ProxmoxServerConfig: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var url: String
    var tokenId: String
    var secret: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case tokenId
        case secret

        // Legacy aliases observed in older/local builds or hand-edited payloads.
        case tokenID
        case token_id = "token_id"
        case apiTokenId
        case api_token_id = "api_token_id"
        case token
        case apiToken
        case tokenSecret
        case token_secret = "token_secret"
        case apiTokenSecret
        case api_token_secret = "api_token_secret"
    }

    init(id: UUID = UUID(), name: String, url: String, tokenId: String, secret: String) {
        self.id = id
        self.name = name
        self.url = url
        self.tokenId = tokenId
        self.secret = secret
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name).trimmingCharacters(in: .whitespacesAndNewlines)
        url = try container.decode(String.self, forKey: .url).trimmingCharacters(in: .whitespacesAndNewlines)
        tokenId = try Self.decodeFirstNonEmptyString(
            from: container,
            keys: [.tokenId, .tokenID, .token_id, .apiTokenId, .api_token_id, .token, .apiToken],
            fieldName: "tokenId"
        )
        secret = try Self.decodeFirstNonEmptyString(
            from: container,
            keys: [.secret, .tokenSecret, .token_secret, .apiTokenSecret, .api_token_secret],
            fieldName: "secret"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(tokenId, forKey: .tokenId)
        try container.encode(secret, forKey: .secret)
    }

    private static func decodeFirstNonEmptyString(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys],
        fieldName: String
    ) throws -> String {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: container.codingPath,
                debugDescription: "Missing required value for \(fieldName)"
            )
        )
    }
    
    var authHeader: String {
        return "PVEAPIToken=\(tokenId)=\(secret)"
    }
    
    var baseWebURL: URL? {
        guard let url = URL(string: self.url) else { return nil }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path = ""
        components?.query = nil
        return components?.url
    }
}

class SettingsService: ObservableObject {
    private enum StorageKeys {
        static let servers = "proxmox_servers"
        static let serversBackup = "proxmox_servers_backup"
        static let serversCorrupt = "proxmox_servers_corrupt"
        static let notifications = "enableNotifications"
        static let legacyNotifications = "notificationsEnabled"
        static let legacyServerKeys = [
            "proxmoxServers",
            "servers"
        ]
    }

    private let defaults: UserDefaults
    private let serversBackupFileURL: URL
    private var isHydratingFromStorage = false

    @Published var servers: [ProxmoxServerConfig] {
        didSet {
            guard !isHydratingFromStorage else { return }
            saveServers()
        }
    }
    
    @Published var activeSheet: SettingsSheet?
    
    @Published var enableNotifications: Bool {
        didSet { defaults.set(enableNotifications, forKey: StorageKeys.notifications) }
    }
    
    init(defaults: UserDefaults = .standard, backupFileURL: URL? = nil) {
        self.defaults = defaults
        self.serversBackupFileURL = backupFileURL ?? Self.defaultBackupFileURL()
        self.servers = []
        self.enableNotifications = Self.loadNotifications(defaults: defaults)
        loadServers()
    }
    
    private func loadServers() {
        if let data = defaults.data(forKey: StorageKeys.servers),
           let decoded = decodeServers(from: data) {
            setServersFromStorage(decoded)
            defaults.set(data, forKey: StorageKeys.serversBackup)
            rewriteCanonicalPayloadIfNeeded(currentData: data, decodedServers: decoded)
            if let persistedData = defaults.data(forKey: StorageKeys.servers) {
                writeServersBackupToDisk(persistedData)
            }
            return
        }

        // Attempt migration from legacy keys used by older/local builds.
        for legacyKey in StorageKeys.legacyServerKeys {
            guard let data = defaults.data(forKey: legacyKey),
                  let decoded = decodeServers(from: data) else {
                continue
            }

            setServersFromStorage(decoded)
            persistServers(decoded, preserveCurrentAsBackup: false)
            print("Migrated settings from legacy key '\(legacyKey)' to '\(StorageKeys.servers)'.")
            return
        }

        if let data = defaults.data(forKey: StorageKeys.servers),
           !data.isEmpty {
            // Preserve undecodable payload for manual recovery/debug.
            defaults.set(data, forKey: StorageKeys.serversCorrupt)
        }

        // Last safety net: recover from the last-known-good backup.
        if let backupData = defaults.data(forKey: StorageKeys.serversBackup),
           let recovered = decodeServers(from: backupData) {
            setServersFromStorage(recovered)
            defaults.set(backupData, forKey: StorageKeys.servers)
            writeServersBackupToDisk(backupData)
            print("Recovered settings from '\(StorageKeys.serversBackup)'.")
            return
        }

        // Final safety net: recover from disk backup if defaults are unavailable/corrupted.
        if let diskData = readServersBackupFromDisk(),
           let recovered = decodeServers(from: diskData) {
            setServersFromStorage(recovered)
            defaults.set(diskData, forKey: StorageKeys.servers)
            defaults.set(diskData, forKey: StorageKeys.serversBackup)
            print("Recovered settings from disk backup.")
        }
    }
    
    private func decodeServers(from data: Data) -> [ProxmoxServerConfig]? {
        do {
            return try JSONDecoder().decode([ProxmoxServerConfig].self, from: data)
        } catch {
            print("Failed decoding '\(StorageKeys.servers)': \(error)")
            return nil
        }
    }

    private func saveServers() {
        persistServers(servers, preserveCurrentAsBackup: true)
    }

    private func persistServers(_ servers: [ProxmoxServerConfig], preserveCurrentAsBackup: Bool) {
        do {
            let encoded = try JSONEncoder().encode(servers)

            if preserveCurrentAsBackup,
               let existingData = defaults.data(forKey: StorageKeys.servers),
               !existingData.isEmpty {
                defaults.set(existingData, forKey: StorageKeys.serversBackup)
            } else if !preserveCurrentAsBackup {
                defaults.set(encoded, forKey: StorageKeys.serversBackup)
            }

            defaults.set(encoded, forKey: StorageKeys.servers)
            if defaults.data(forKey: StorageKeys.serversBackup) == nil {
                defaults.set(encoded, forKey: StorageKeys.serversBackup)
            }
            writeServersBackupToDisk(encoded)
        } catch {
            print("Failed encoding '\(StorageKeys.servers)': \(error)")
        }
    }

    private func setServersFromStorage(_ loadedServers: [ProxmoxServerConfig]) {
        isHydratingFromStorage = true
        defer { isHydratingFromStorage = false }
        servers = loadedServers
    }

    private func rewriteCanonicalPayloadIfNeeded(currentData: Data, decodedServers: [ProxmoxServerConfig]) {
        guard let canonicalData = try? JSONEncoder().encode(decodedServers),
              canonicalData != currentData else {
            return
        }

        defaults.set(canonicalData, forKey: StorageKeys.servers)
        defaults.set(canonicalData, forKey: StorageKeys.serversBackup)
    }

    private static func defaultBackupFileURL() -> URL {
        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let domain = Bundle.main.bundleIdentifier ?? "com.proxmoxbar.app"

        return baseDirectory
            .appendingPathComponent(domain, isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent("proxmox_servers.json", isDirectory: false)
    }

    private func writeServersBackupToDisk(_ data: Data) {
        let backupDirectory = serversBackupFileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            try data.write(to: serversBackupFileURL, options: .atomic)
        } catch {
            print("Failed writing disk backup: \(error)")
        }
    }

    private func readServersBackupFromDisk() -> Data? {
        do {
            let data = try Data(contentsOf: serversBackupFileURL)
            return data.isEmpty ? nil : data
        } catch {
            return nil
        }
    }

    private static func loadNotifications(defaults: UserDefaults) -> Bool {
        if defaults.object(forKey: StorageKeys.notifications) != nil {
            return defaults.bool(forKey: StorageKeys.notifications)
        }

        if defaults.object(forKey: StorageKeys.legacyNotifications) != nil {
            let legacyValue = defaults.bool(forKey: StorageKeys.legacyNotifications)
            defaults.set(legacyValue, forKey: StorageKeys.notifications)
            return legacyValue
        }

        return false
    }
    
    func addServer(_ server: ProxmoxServerConfig) {
        servers.append(server)
    }
    
    func removeServer(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
    }
    
    func removeServer(id: UUID) {
        if let index = servers.firstIndex(where: { $0.id == id }) {
            servers.remove(at: index)
        }
    }
    
    func updateServer(_ server: ProxmoxServerConfig) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        }
    }
    
    func moveServer(from source: IndexSet, to destination: Int) {
        servers.move(fromOffsets: source, toOffset: destination)
    }
    
    var isEmpty: Bool {
        return servers.isEmpty
    }
    
    var isValid: Bool {
        return !servers.isEmpty
    }
}
