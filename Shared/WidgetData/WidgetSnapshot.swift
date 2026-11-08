struct WidgetSnapshot: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let reachable: Bool
    let nodesOnline: Int
    let nodesTotal: Int
    let running: Int
    let guestsTotal: Int
    let cpu: Double?
    let memory: Double?
    let storage: Double?
}
