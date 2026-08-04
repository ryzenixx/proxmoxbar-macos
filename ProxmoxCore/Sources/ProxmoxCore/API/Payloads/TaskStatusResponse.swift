import Foundation

struct TaskStatusResponse: Decodable {
    struct Task: Decodable {
        let status: String
        let exitstatus: String?

        var hasStopped: Bool { status == "stopped" }
        var hasSucceeded: Bool { exitstatus == "OK" }
    }

    let data: Task
}
