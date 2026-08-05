import Foundation

struct ProxmoxStorage: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let node: String?
    let status: String?
    let used: Int?
    let total: Int?
    let content: [String]
    let pluginType: String?
    let isShared: Bool

    var usage: Double? {
        guard let used, let total, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    var isAvailable: Bool {
        status?.lowercased() == "available"
    }
}
