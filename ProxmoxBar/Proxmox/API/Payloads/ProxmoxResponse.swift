import Foundation

struct ProxmoxResponse<Payload: Decodable & Sendable>: Decodable, Sendable {
    let data: Payload
}

struct VersionPayload: Decodable, Sendable {
    let version: String
    let release: String
    let repoid: String
}

struct TaskStatusPayload: Decodable, Sendable {
    let upid: String
    let node: String
    let status: String
    let exitstatus: String?

    var isFinished: Bool {
        status.lowercased() == "stopped"
    }

    var succeeded: Bool {
        exitstatus?.uppercased() == "OK"
    }
}
