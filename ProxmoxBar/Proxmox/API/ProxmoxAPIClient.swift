import Foundation

struct ProxmoxAPIClient: ProxmoxAPI {
    private enum Limits {
        static let taskPollInterval: Duration = .seconds(1)
        static let taskPollAttempts = 30
    }

    private let transport: ProxmoxHTTPTransport

    init(configuration: URLSessionConfiguration = .ephemeral) {
        transport = ProxmoxHTTPTransport(configuration: configuration)
    }

    func version(of server: ProxmoxServer) async throws -> ServerVersion {
        let payload: VersionPayload = try await transport.request(["version"], from: server)
        return ServerVersion(
            version: payload.version,
            release: payload.release,
            repositoryID: payload.repoid
        )
    }

    func clusterState(of server: ProxmoxServer) async throws -> ClusterState {
        let resources: [ClusterResource] = try await transport.request(
            ["cluster", "resources"],
            from: server
        )
        return ClusterState(resources: resources)
    }

    func perform(
        _ action: GuestAction,
        on guest: ProxmoxGuest,
        of server: ProxmoxServer
    ) async throws {
        let upid: String = try await transport.request(
            [
                "nodes", guest.node, guest.kind.pathComponent, String(guest.vmid),
                "status", action.pathComponent,
            ],
            method: .post,
            from: server
        )
        try await waitForTask(upid, on: guest.node, of: server)
    }

    private func waitForTask(
        _ upid: String,
        on node: String,
        of server: ProxmoxServer
    ) async throws {
        let segments = ["nodes", node, "tasks", upid, "status"]

        for _ in 0..<Limits.taskPollAttempts {
            let status: TaskStatusPayload = try await transport.request(segments, from: server)
            if status.isFinished {
                guard status.succeeded else {
                    throw ProxmoxError.taskFailed(status.exitstatus ?? "The task failed.")
                }
                return
            }
            try await Task.sleep(for: Limits.taskPollInterval)
        }
        throw ProxmoxError.timedOut
    }
}
