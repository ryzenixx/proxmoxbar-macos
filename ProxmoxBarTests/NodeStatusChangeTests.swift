import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Node status changes")
struct NodeStatusChangeTests {
    private func nodes(_ statuses: [(name: String, status: String)]) throws -> [ProxmoxNode] {
        let items = statuses.map { entry in
            """
            {"id":"node/\(entry.name)","type":"node","node":"\(entry.name)",\
            "status":"\(entry.status)"}
            """
        }
        let json = "[\(items.joined(separator: ","))]"
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return ClusterState(resources: resources).nodes
    }

    private func snapshot(of nodes: [ProxmoxNode]) -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.name, $0.isOnline) })
    }

    @Test("The first read notifies nothing")
    func firstReadIsSilent() throws {
        let current = try nodes([("a", "online")])
        #expect(NodeStatusChange.detect(previous: [:], current: current).isEmpty)
    }

    @Test("A node going offline is reported")
    func reportsGoingOffline() throws {
        let previous = snapshot(of: try nodes([("a", "online")]))
        let current = try nodes([("a", "offline")])
        let changes = NodeStatusChange.detect(previous: previous, current: current)
        #expect(changes.count == 1)
        #expect(changes.first?.isOnline == false)
    }

    @Test("A node coming back is reported")
    func reportsComingBack() throws {
        let previous = snapshot(of: try nodes([("a", "offline")]))
        let current = try nodes([("a", "online")])
        let changes = NodeStatusChange.detect(previous: previous, current: current)
        #expect(changes.first?.isOnline == true)
    }

    @Test("A node that did not change is not reported")
    func ignoresUnchanged() throws {
        let previous = snapshot(of: try nodes([("a", "online")]))
        let current = try nodes([("a", "online")])
        #expect(NodeStatusChange.detect(previous: previous, current: current).isEmpty)
    }
}
