import Foundation

public protocol ProxmoxAPI: Sendable {
    func version(url: String, authHeader: String) async throws -> ServerVersion

    func snapshot(url: String, authHeader: String) async throws -> ClusterSnapshot

    func guestStatus(
        node: String,
        vmid: Int,
        type: String,
        url: String,
        authHeader: String
    ) async throws -> GuestStatus

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
