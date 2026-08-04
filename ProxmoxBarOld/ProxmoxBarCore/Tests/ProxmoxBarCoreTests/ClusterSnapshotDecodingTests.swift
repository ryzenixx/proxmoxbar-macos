import Foundation
import Testing

@testable import ProxmoxBarCore

@Suite("Decoding a real /cluster/resources payload")
struct ClusterSnapshotDecodingTests {
    private func snapshot() throws -> ClusterSnapshot {
        let data = try Fixture.data(Fixture.clusterResources)
        let response = try JSONDecoder().decode(ClusterResourcesResponse.self, from: data)
        return ClusterSnapshot(response.data)
    }

    @Test("every resource type is partitioned")
    func partitionsByType() throws {
        let snapshot = try snapshot()

        #expect(snapshot.nodes.count == 1)
        #expect(snapshot.storages.count == 3)
        #expect(snapshot.guests.count == 13)
        #expect(snapshot.networks.count == 1)
        #expect(snapshot.pools.isEmpty)
        #expect(snapshot.sdnZones.isEmpty)
    }

    @Test("a guest with no name falls back to its vmid")
    func fallsBackToVMID() throws {
        let guest = try #require(try snapshot().guests.first { $0.vmid == 999 })

        #expect(guest.name == nil)
        #expect(guest.displayName == "999")
    }

    @Test("a guest with no status is kept, not dropped")
    func keepsGuestWithoutStatus() throws {
        let guest = try #require(try snapshot().guests.first { $0.vmid == 999 })

        #expect(guest.status == "unknown")
        #expect(guest.isRunning == false)
    }

    @Test("Proxmox sends booleans as 0 and 1")
    func decodesIntegerBooleans() throws {
        let snapshot = try snapshot()
        let template = try #require(snapshot.guests.first { $0.vmid == 999 })
        let regular = try #require(snapshot.guests.first { $0.vmid == 100 })

        #expect(template.isTemplate)
        #expect(regular.isTemplate == false)
        #expect(snapshot.storages.contains { $0.isShared })
        #expect(snapshot.storages.contains { !$0.isShared })
    }

    @Test("a template refuses power actions")
    func templateRefusesActions() throws {
        let template = try #require(try snapshot().guests.first { $0.vmid == 999 })

        #expect(template.acceptsPowerActions == false)
    }

    @Test("tags are split into a list")
    func splitsTags() throws {
        let snapshot = try snapshot()
        let multiple = try #require(snapshot.guests.first { $0.vmid == 999 })
        let single = try #require(snapshot.guests.first { $0.vmid == 100 })

        #expect(multiple.tags == ["prod", "web"])
        #expect(single.tags == ["docker"])
    }

    @Test("storage content types are split into a list")
    func splitsContentTypes() throws {
        let storages = try snapshot().storages

        #expect(storages.contains { $0.contentTypes.count > 1 })
        #expect(storages.allSatisfy { !$0.contentTypes.contains("") })
    }

    @Test("guests are sorted by vmid and storages by usage")
    func sortsResults() throws {
        let snapshot = try snapshot()

        #expect(snapshot.guests.map(\.vmid) == snapshot.guests.map(\.vmid).sorted())

        let usages = snapshot.storages.map(\.diskUsage)
        #expect(usages == usages.sorted(by: >))
    }

    @Test("containers and virtual machines are told apart")
    func classifiesGuests() throws {
        let snapshot = try snapshot()

        #expect(snapshot.guests.filter(\.isVirtualMachine).count == 2)
        #expect(snapshot.guests.filter(\.isContainer).count == 11)
    }

    @Test("node metrics survive the round trip")
    func readsNodeMetrics() throws {
        let node = try #require(try snapshot().nodes.first)

        #expect(node.isOnline)
        #expect(node.uptime != nil)
        #expect(node.cgroupMode == 2)
        #expect(node.maxcpu == 12)
    }

    @Test("a network entity is decoded")
    func readsNetwork() throws {
        let network = try #require(try snapshot().networks.first)

        #expect(network.networkType == "zone")
        #expect(network.node == "pve")
    }

    @Test("an unknown resource type is ignored rather than fatal")
    func ignoresUnknownType() throws {
        let payload = Data(
            #"{"data":[{"id":"weird/1","type":"quantum-flux","status":"ok"}]}"#.utf8
        )
        let response = try JSONDecoder().decode(ClusterResourcesResponse.self, from: payload)
        let snapshot = ClusterSnapshot(response.data)

        #expect(snapshot == .empty)
    }
}
