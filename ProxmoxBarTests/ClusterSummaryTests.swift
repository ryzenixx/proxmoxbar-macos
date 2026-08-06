import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Cluster summary")
struct ClusterSummaryTests {
    private func state(_ json: String) throws -> ClusterState {
        let data = try #require(json.data(using: .utf8))
        return ClusterState(resources: try JSONDecoder().decode([ClusterResource].self, from: data))
    }

    @Test("Only online nodes are counted")
    func countsOnlineNodes() throws {
        let result = try state(
            """
            [
              {"id":"node/a","type":"node","node":"a","status":"online"},
              {"id":"node/b","type":"node","node":"b","status":"offline"}
            ]
            """
        )
        #expect(result.onlineNodes == 1)
        #expect(result.nodes.count == 2)
    }

    @Test("Only running guests are counted")
    func countsRunningGuests() throws {
        let result = try state(
            """
            [
              {"id":"qemu/1","type":"qemu","vmid":1,"node":"a","status":"running"},
              {"id":"lxc/2","type":"lxc","vmid":2,"node":"a","status":"stopped"}
            ]
            """
        )
        #expect(result.runningGuests == 1)
    }

    @Test("CPU is weighted by core count, not averaged across nodes")
    func weightsCPUByCores() throws {
        let result = try state(
            """
            [
              {"id":"node/a","type":"node","node":"a","status":"online","cpu":1.0,"maxcpu":8},
              {"id":"node/b","type":"node","node":"b","status":"online","cpu":0.0,"maxcpu":2}
            ]
            """
        )
        let usage = try #require(result.cpuUsage)
        #expect(abs(usage - 0.8) < 0.001)
        #expect(result.totalCores == 10)
    }

    @Test("Memory is the sum used over the sum available")
    func sumsMemory() throws {
        let result = try state(
            """
            [
              {"id":"node/a","type":"node","node":"a","status":"online","mem":2,"maxmem":8},
              {"id":"node/b","type":"node","node":"b","status":"online","mem":2,"maxmem":8}
            ]
            """
        )
        let memory = try #require(result.memory)
        #expect(memory.used == 4)
        #expect(memory.total == 16)
        #expect(abs(memory.ratio - 0.25) < 0.001)
    }

    @Test("A cluster reporting no capacity has no usage to show")
    func noCapacityMeansNoUsage() throws {
        let result = try state(
            """
            [{"id":"node/a","type":"node","node":"a","status":"online"}]
            """
        )
        #expect(result.cpuUsage == nil)
        #expect(result.memory == nil)
    }

    @Test("A shared storage reported by every node is counted once")
    func countsSharedStorageOnce() throws {
        let result = try state(
            """
            [
              {"id":"storage/a/ceph","type":"storage","storage":"ceph","node":"a",
               "shared":1,"disk":100,"maxdisk":400,"status":"available"},
              {"id":"storage/b/ceph","type":"storage","storage":"ceph","node":"b",
               "shared":1,"disk":100,"maxdisk":400,"status":"available"}
            ]
            """
        )
        let capacity = try #require(result.storage)
        #expect(capacity.total == 400)
        #expect(capacity.used == 100)
    }

    @Test("Local storages sharing a name are summed, not deduplicated")
    func sumsLocalStoragePerNode() throws {
        let result = try state(
            """
            [
              {"id":"storage/a/local","type":"storage","storage":"local","node":"a",
               "shared":0,"disk":50,"maxdisk":200,"status":"available"},
              {"id":"storage/b/local","type":"storage","storage":"local","node":"b",
               "shared":0,"disk":50,"maxdisk":200,"status":"available"}
            ]
            """
        )
        let capacity = try #require(result.storage)
        #expect(capacity.total == 400)
        #expect(capacity.used == 100)
    }

    @Test("An unavailable storage is left out of the total")
    func ignoresUnavailableStorage() throws {
        let result = try state(
            """
            [
              {"id":"storage/a/local","type":"storage","storage":"local","node":"a",
               "disk":50,"maxdisk":200,"status":"available"},
              {"id":"storage/a/nfs","type":"storage","storage":"nfs","node":"a",
               "disk":0,"maxdisk":900,"status":"unavailable"}
            ]
            """
        )
        let capacity = try #require(result.storage)
        #expect(capacity.total == 200)
    }

    @Test("A storage that reports no status is still counted")
    func countsStorageWithoutStatus() throws {
        let result = try state(
            """
            [{"id":"storage/a/local","type":"storage","storage":"local","node":"a",
              "disk":50,"maxdisk":200}]
            """
        )
        let capacity = try #require(result.storage)
        #expect(capacity.total == 200)
    }

    @Test("A cluster with no storage has nothing to report")
    func noStorageMeansNoCapacity() throws {
        let result = try state(
            """
            [{"id":"node/a","type":"node","node":"a","status":"online"}]
            """
        )
        #expect(result.storage == nil)
    }

    @Test("Usage never exceeds a full meter")
    func usageIsClamped() throws {
        let result = try state(
            """
            [{"id":"node/a","type":"node","node":"a","status":"online","cpu":1.4,"maxcpu":4}]
            """
        )
        #expect(result.cpuUsage == 1)
        #expect(ClusterCapacity(used: 12, total: 8).ratio == 1)
    }
}
