import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Guest sort and search")
struct GuestSortTests {
    private func guests(_ json: String) throws -> [ProxmoxGuest] {
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return ClusterState(resources: resources).guests
    }

    private let sample = """
        [
          {"id":"qemu/101","type":"qemu","vmid":101,"node":"a","status":"running","name":"beta"},
          {"id":"lxc/100","type":"lxc","vmid":100,"node":"a","status":"stopped","name":"alpha"},
          {"id":"qemu/102","type":"qemu","vmid":102,"node":"a","status":"stopped","name":"gamma"}
        ]
        """

    @Test("Sorting by identifier orders by vmid")
    func sortsByIdentifier() throws {
        let result = GuestSort.identifier.arrange(try guests(sample), matching: "")
        #expect(result.map(\.vmid) == [100, 101, 102])
    }

    @Test("Sorting by name is case-insensitive and alphabetical")
    func sortsByName() throws {
        let result = GuestSort.name.arrange(try guests(sample), matching: "")
        #expect(result.map(\.displayName) == ["alpha", "beta", "gamma"])
    }

    @Test("Sorting by status puts running guests first")
    func sortsByStatus() throws {
        let result = GuestSort.status.arrange(try guests(sample), matching: "")
        #expect(result.first?.vmid == 101)
    }

    @Test("Search matches the name, case-insensitively")
    func searchesByName() throws {
        let result = GuestSort.identifier.arrange(try guests(sample), matching: "ALPH")
        #expect(result.map(\.displayName) == ["alpha"])
    }

    @Test("Search matches the vmid")
    func searchesByIdentifier() throws {
        let result = GuestSort.identifier.arrange(try guests(sample), matching: "102")
        #expect(result.map(\.vmid) == [102])
    }

    @Test("A blank query keeps every guest")
    func blankQueryKeepsEverything() throws {
        let result = GuestSort.identifier.arrange(try guests(sample), matching: "   ")
        #expect(result.count == 3)
    }
}
