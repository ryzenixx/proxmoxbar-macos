import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Guest status changes")
struct GuestStatusChangeTests {
    private func guests(_ statuses: [(vmid: Int, status: String)]) throws -> [ProxmoxGuest] {
        let items = statuses.map { entry in
            """
            {"id":"qemu/\(entry.vmid)","type":"qemu","vmid":\(entry.vmid),\
            "node":"a","status":"\(entry.status)"}
            """
        }
        let json = "[\(items.joined(separator: ","))]"
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return ClusterState(resources: resources).guests
    }

    private func snapshot(of guests: [ProxmoxGuest]) -> [String: GuestStatus] {
        Dictionary(uniqueKeysWithValues: guests.map { ($0.id, $0.status) })
    }

    @Test("The first read notifies nothing")
    func firstReadIsSilent() throws {
        let current = try guests([(1, "running")])
        #expect(GuestStatusChange.detect(previous: [:], current: current, skipping: []).isEmpty)
    }

    @Test("A genuine transition is reported")
    func reportsTransition() throws {
        let previous = snapshot(of: try guests([(1, "running")]))
        let current = try guests([(1, "stopped")])
        let changes = GuestStatusChange.detect(previous: previous, current: current, skipping: [])
        #expect(changes.count == 1)
        #expect(changes.first?.status == .stopped)
    }

    @Test("An unchanged status is not reported")
    func ignoresUnchanged() throws {
        let previous = snapshot(of: try guests([(1, "running")]))
        let current = try guests([(1, "running")])
        let changes = GuestStatusChange.detect(previous: previous, current: current, skipping: [])
        #expect(changes.isEmpty)
    }

    @Test("A self-initiated change is skipped")
    func skipsSelfInitiated() throws {
        let before = try guests([(1, "running")])
        let previous = snapshot(of: before)
        let current = try guests([(1, "stopped")])
        let skip = Set(before.map(\.id))
        let changes = GuestStatusChange.detect(
            previous: previous, current: current, skipping: skip
        )
        #expect(changes.isEmpty)
    }

    @Test("A newly appeared guest is not reported")
    func ignoresNewGuest() throws {
        let previous = snapshot(of: try guests([(1, "running")]))
        let current = try guests([(1, "running"), (2, "stopped")])
        let changes = GuestStatusChange.detect(previous: previous, current: current, skipping: [])
        #expect(changes.isEmpty)
    }
}
