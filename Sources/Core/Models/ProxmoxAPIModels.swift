import Foundation

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

struct ProxmoxResourceResponse: Codable {
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
