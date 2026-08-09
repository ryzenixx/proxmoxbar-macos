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

    var isUnavailable: Bool {
        status?.lowercased() == "unavailable"
    }

    var capacitySummary: String? {
        guard let used, let total, total > 0 else { return nil }
        let usedText = Int64(used).formatted(.byteCount(style: .file))
        let totalText = Int64(total).formatted(.byteCount(style: .file))
        return "\(usedText) of \(totalText)"
    }

    var percentageText: String? {
        guard let usage else { return nil }
        return "\(Int((usage * 100).rounded()))%"
    }
}
