import Foundation

public protocol ProxmoxAPI: Sendable {
    func snapshot(url: String, authHeader: String) async throws -> ClusterSnapshot

    func performGuestAction(
        _ action: GuestAction,
        node: String,
        vmid: Int,
        type: String,
        url: String,
        authHeader: String
    ) async throws -> String

    func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws
}
