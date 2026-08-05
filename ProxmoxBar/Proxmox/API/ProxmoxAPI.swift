import Foundation

protocol ProxmoxAPI: Sendable {
    func version(of server: ProxmoxServer) async throws -> ServerVersion
    func clusterState(of server: ProxmoxServer) async throws -> ClusterState
    func perform(
        _ action: GuestAction,
        on guest: ProxmoxGuest,
        of server: ProxmoxServer
    ) async throws
}
