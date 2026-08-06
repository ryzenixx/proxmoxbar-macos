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

struct GuestStatusPayload: Decodable, Sendable {
    let status: String
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
