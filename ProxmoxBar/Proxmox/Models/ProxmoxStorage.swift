import Foundation

struct ProxmoxStorage: Identifiable, Hashable, Sendable {
    enum Availability: Hashable, Sendable {
        case available
        case unavailable
        case unknown

        init(status: String?) {
            switch status?.lowercased() {
            case "available": self = .available
            case "unavailable": self = .unavailable
            default: self = .unknown
            }
        }

        var message: String? {
            switch self {
            case .available: nil
            case .unavailable: "Unavailable"
            case .unknown: "Status unknown"
            }
        }
    }

    let id: String
    let name: String
    let node: String?
    let availability: Availability
    let used: Int?
    let total: Int?
    let content: [String]
    let pluginType: String?
    let isShared: Bool

    var isAvailable: Bool { availability == .available }

    var usage: Double? {
        guard isAvailable, let used, let total, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    var capacitySummary: String? {
        guard isAvailable, let used, let total, total > 0 else { return nil }
        let usedText = Int64(used).formatted(.byteCount(style: .file))
        let totalText = Int64(total).formatted(.byteCount(style: .file))
        return "\(usedText) of \(totalText)"
    }
}
