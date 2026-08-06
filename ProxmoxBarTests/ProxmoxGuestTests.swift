import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Guest")
struct ProxmoxGuestTests {
    private func guest(_ json: String) throws -> ProxmoxGuest {
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return try #require(ClusterState(resources: resources).guests.first)
    }

    @Test("Memory usage is the share of the allocated maximum")
    func reportsMemoryShare() throws {
        let result = try guest(
            """
            [{"id":"qemu/1","type":"qemu","vmid":1,"node":"a","status":"running",
              "mem":2048,"maxmem":8192}]
            """
        )
        let usage = try #require(result.memoryUsage)
        #expect(abs(usage - 0.25) < 0.001)
    }

    @Test("A guest reporting no memory ceiling has no usage to show")
    func noCeilingMeansNoUsage() throws {
        let result = try guest(
            """
            [{"id":"qemu/1","type":"qemu","vmid":1,"node":"a","status":"stopped"}]
            """
        )
        #expect(result.memoryUsage == nil)
    }

    @Test("Memory usage never exceeds a full meter")
    func memoryUsageIsClamped() throws {
        let result = try guest(
            """
            [{"id":"lxc/2","type":"lxc","vmid":2,"node":"a","status":"running",
              "mem":9000,"maxmem":8192}]
            """
        )
        #expect(result.memoryUsage == 1)
    }

    @Test("A guest without a name falls back to its identifier")
    func fallsBackToVMID() throws {
        let result = try guest(
            """
            [{"id":"qemu/108","type":"qemu","vmid":108,"node":"a","status":"stopped"}]
            """
        )
        #expect(result.displayName == "108")
    }

    @Test("A template accepts no power action")
    func templateRefusesPowerActions() throws {
        let result = try guest(
            """
            [{"id":"qemu/9000","type":"qemu","vmid":9000,"node":"a","status":"stopped",
              "template":1}]
            """
        )
        #expect(result.isTemplate)
        #expect(result.acceptsPowerActions == false)
    }
}
