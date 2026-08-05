import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Cluster resources decoding")
struct ClusterStateDecodingTests {
    private func snapshot(_ json: String) throws -> ClusterState {
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return ClusterState(resources: resources)
    }

    @Test("Resources are partitioned by their type discriminator")
    func partitionsByType() throws {
        let result = try snapshot(
            """
            [
              {"id":"node/pve","type":"node","node":"pve","status":"online"},
              {"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"running"},
              {"id":"lxc/200","type":"lxc","vmid":200,"node":"pve","status":"stopped"},
              {"id":"storage/pve/local","type":"storage","storage":"local","node":"pve"},
              {"id":"pool/prod","type":"pool"},
              {"id":"sdn/zone1","type":"sdn"}
            ]
            """
        )
        #expect(result.nodes.count == 1)
        #expect(result.guests.count == 2)
        #expect(result.storages.count == 1)
        #expect(result.discardedCount == 0)
    }

    @Test("Booleans arrive as 0 and 1, not as true and false")
    func decodesNumericBooleans() throws {
        let result = try snapshot(
            """
            [
              {"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"stopped","template":1},
              {"id":"qemu/101","type":"qemu","vmid":101,"node":"pve","status":"running","template":0},
              {"id":"storage/pve/nfs","type":"storage","storage":"nfs","node":"pve","shared":1}
            ]
            """
        )
        #expect(result.guests.count == 2)
        #expect(result.guests[0].isTemplate)
        #expect(result.guests[1].isTemplate == false)
        #expect(result.storages[0].isShared)
    }

    @Test("A guest without a name falls back to its vmid")
    func guestWithoutNameKeepsIdentity() throws {
        let result = try snapshot(
            """
            [{"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"running"}]
            """
        )
        let guest = try #require(result.guests.first)
        #expect(guest.name == nil)
        #expect(guest.displayName == "100")
    }

    @Test("Hyphenated keys from the schema are decoded")
    func decodesHyphenatedKeys() throws {
        let result = try snapshot(
            """
            [{"id":"node/pve","type":"node","node":"pve","status":"online","host-arch":"aarch64"}]
            """
        )
        #expect(result.nodes.first?.architecture == "aarch64")
    }

    @Test("Tags and storage content are split on commas and semicolons")
    func splitsLists() throws {
        let result = try snapshot(
            """
            [
              {"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"running","tags":"prod;web"},
              {"id":"storage/pve/local","type":"storage","storage":"local","node":"pve",
               "content":"images,iso,backup"}
            ]
            """
        )
        #expect(result.guests.first?.tags == ["prod", "web"])
        #expect(result.storages.first?.content == ["images", "iso", "backup"])
    }

    @Test("An entry missing what its kind requires is discarded, not fatal")
    func discardsIncompleteEntries() throws {
        let result = try snapshot(
            """
            [
              {"id":"qemu/100","type":"qemu","node":"pve","status":"running"},
              {"id":"qemu/101","type":"qemu","vmid":101,"node":"pve","status":"running"}
            ]
            """
        )
        #expect(result.guests.count == 1)
        #expect(result.discardedCount == 1)
    }

    @Test("A resource type this version does not model is ignored silently")
    func ignoresUnmodelledTypes() throws {
        let result = try snapshot(
            """
            [{"id":"network/fabric1","type":"network","network":"fabric1","network-type":"fabric"}]
            """
        )
        #expect(result.nodes.isEmpty)
        #expect(result.guests.isEmpty)
        #expect(result.discardedCount == 0)
    }

    @Test("Storage usage is a ratio of used over total")
    func computesStorageUsage() throws {
        let result = try snapshot(
            """
            [{"id":"storage/pve/local","type":"storage","storage":"local","node":"pve",
              "disk":25,"maxdisk":100}]
            """
        )
        #expect(result.storages.first?.usage == 0.25)
    }

    @Test("A template or a locked guest refuses power actions")
    func powerActionEligibility() throws {
        let result = try snapshot(
            """
            [
              {"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"stopped","template":1},
              {"id":"qemu/101","type":"qemu","vmid":101,"node":"pve","status":"running",
               "lock":"backup"},
              {"id":"qemu/102","type":"qemu","vmid":102,"node":"pve","status":"running"}
            ]
            """
        )
        #expect(result.guests[0].acceptsPowerActions == false)
        #expect(result.guests[1].acceptsPowerActions == false)
        #expect(result.guests[2].acceptsPowerActions)
    }
}
