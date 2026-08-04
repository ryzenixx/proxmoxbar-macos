import Foundation

/// Everything one refresh reads from a Proxmox host.
public struct ClusterSnapshot: Sendable, Equatable {
    public let nodes: [ProxmoxNode]
    public let storages: [ProxmoxStorage]
    public let guests: [ProxmoxVM]

    public init(nodes: [ProxmoxNode], storages: [ProxmoxStorage], guests: [ProxmoxVM]) {
        self.nodes = nodes
        self.storages = storages
        self.guests = guests
    }

    public static let empty = ClusterSnapshot(nodes: [], storages: [], guests: [])
}

/// The boundary the rest of the app depends on, so a model can be exercised
/// without performing a request. The client itself is tested against a stubbed
/// `URLProtocol` rather than through this protocol. See docs/ADR/0022.
public protocol ProxmoxAPI: Sendable {
    func snapshot(url: String, authHeader: String) async throws -> ClusterSnapshot

    func performNodeAction(
        node: String,
        vmid: Int,
        type: String,
        action: String,
        url: String,
        authHeader: String
    ) async throws -> String

    func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws
}

public enum ProxmoxError: Error, LocalizedError, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case apiError(Int, String)
    case invalidCredentials
    case taskFailed(String)
    case taskTimedOut

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Server URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Received invalid data: \(message)"
        case .apiError(let statusCode, let message):
            return "Proxmox API Error (\(statusCode)): \(message)"
        case .invalidCredentials:
            return "Invalid Credentials / Missing Config"
        case .taskFailed(let status):
            return "Task failed: \(status)"
        case .taskTimedOut:
            return "Task timed out"
        }
    }
}
