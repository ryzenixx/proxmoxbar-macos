import Foundation

public enum ProxmoxError: Error, LocalizedError, Equatable {
    case invalidURL
    case unauthorized
    case apiError(statusCode: Int, message: String)
    case networkError(String)
    case decodingError(String)
    case taskFailed(exitStatus: String)
    case taskTimedOut

    public var isRetryable: Bool {
        if case .networkError = self { return true }
        return false
    }

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return
                "The server URL must start with https:// and include the host, for example https://pve.local:8006"
        case .unauthorized:
            return "Unauthorized. Check the API token."
        case .apiError(let statusCode, let message):
            return "Proxmox returned \(statusCode): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Received unexpected data: \(message)"
        case .taskFailed(let exitStatus):
            return "The task failed: \(exitStatus)"
        case .taskTimedOut:
            return "The task did not finish in time."
        }
    }
}
