import Foundation

// The wire format of the Proxmox endpoints this app calls. Internal on purpose:
// nothing outside the package should know what the API looks like.
//
// `/cluster/resources` returns one heterogeneous array, so nearly every field is
// optional and the `type` discriminator decides which ones are meaningful. An
// entry missing a field its kind requires is dropped rather than failing the
// whole response. See docs/ADR/0004.

struct ProxmoxRawResource: Codable {
    let id: String?
    let vmid: Int?
    let name: String?
    let status: String?
    let type: String?
    let node: String?

    let cpu: Double?
    let maxcpu: Double?
    let mem: Int64?
    let maxmem: Int64?
    let disk: Int64?
    let maxdisk: Int64?

    let storage: String?
    let plugintype: String?
    let content: String?
}

struct ClusterResourcesResponse: Codable {
    let data: [ProxmoxRawResource]
}

struct UPIDResponse: Decodable {
    let data: String
}

struct TaskStatusResponse: Decodable {
    struct TaskData: Decodable {
        let status: String
        let exitstatus: String?

        var isStopped: Bool { status == "stopped" }
        var isSuccess: Bool { exitstatus == "OK" }
    }

    let data: TaskData
}
