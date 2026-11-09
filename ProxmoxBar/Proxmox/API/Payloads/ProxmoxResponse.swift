import Foundation

struct ProxmoxResponse<Payload: Decodable & Sendable>: Decodable, Sendable {
    let data: Payload
}

struct ProxmoxFailurePayload: Decodable, Sendable {
    let message: String?
    let errors: [String: String]?

    var reason: String? {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let errors, !errors.isEmpty else { return nil }
        return
            errors
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }
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

    func completion() throws -> TaskCompletion? {
        guard status.lowercased() == "stopped", let exitstatus, !exitstatus.isEmpty else {
            return nil
        }
        if exitstatus.uppercased() == "OK" { return .succeeded }
        let prefix = "WARNINGS: "
        if exitstatus.hasPrefix(prefix), let count = Int(exitstatus.dropFirst(prefix.count)),
            count > 0
        {
            return .warnings(count)
        }
        throw ProxmoxError.taskFailed(exitstatus)
    }
}
