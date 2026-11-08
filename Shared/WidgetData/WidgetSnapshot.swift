import Foundation

struct WidgetSnapshot: Codable, Hashable, Identifiable, Sendable {
    private static let freshnessInterval: TimeInterval = 30 * 60

    let id: String
    let name: String
    let reachable: Bool
    let observedAt: Date?
    let nodesOnline: Int
    let nodesTotal: Int
    let running: Int
    let guestsTotal: Int
    let cpu: Double?
    let memory: Double?
    let storage: Double?

    var staleAt: Date? {
        observedAt?.addingTimeInterval(Self.freshnessInterval)
    }

    func isStale(at date: Date) -> Bool {
        guard let staleAt else { return true }
        return date.timeIntervalSince(staleAt) >= 0
    }
}
