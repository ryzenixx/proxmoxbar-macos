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
    @Published var servers: [ProxmoxServerConfig] {
        didSet { saveServers() }
    }
    
    @Published var activeSheet: SettingsSheet?
    
    @Published var enableNotifications: Bool {
        didSet { UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications") }
    }
    
    init() {
        self.servers = []
        self.enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
        loadServers()
    }
    
    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: "proxmox_servers"),
           let decoded = try? JSONDecoder().decode([ProxmoxServerConfig].self, from: data) {
            self.servers = decoded
        }
    }
    
    private func saveServers() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: "proxmox_servers")
        }
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
