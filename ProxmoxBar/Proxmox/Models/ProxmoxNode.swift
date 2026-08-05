import Foundation

struct ProxmoxNode: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let status: String
    let cpu: Double?
    let maxCPUs: Double?
    let memory: Int?
    let maximumMemory: Int?
    let disk: Int?
    let maximumDisk: Int?
    let uptime: Int?
    let level: String?
    let architecture: String?

    var isOnline: Bool {
        status.lowercased() == "online"
    }
}
