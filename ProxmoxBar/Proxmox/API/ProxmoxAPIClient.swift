import Foundation

struct ProxmoxAPIClient: ProxmoxAPI {
    private enum Limits {
        static let taskPollInterval: Duration = .seconds(1)
        // Proxmox allows 60 seconds for a clean shutdown by default.
        static let taskTimeout: Duration = .seconds(90)
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
    ) async throws -> TaskCompletion {
        let upid: String = try await transport.request(
            [
                "nodes", guest.node, guest.kind.pathComponent, String(guest.vmid),
                "status", action.pathComponent,
            ],
            method: .post,
            from: server
        )
        return try await waitForTask(upid, of: server)
    }

    private func waitForTask(_ upid: String, of server: ProxmoxServer) async throws
        -> TaskCompletion
    {
        let parts = upid.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "UPID", !parts[1].isEmpty, !parts[2].isEmpty else {
            throw ProxmoxError.taskStatusUnconfirmed
        }
        let segments = ["nodes", String(parts[1]), "tasks", upid, "status"]
        let deadline = ContinuousClock.now.advanced(by: Limits.taskTimeout)

        while ContinuousClock.now < deadline {
            try Task.checkCancellation()
            do {
                let status: TaskStatusPayload = try await transport.request(segments, from: server)
                if let completion = try status.completion() { return completion }
            } catch let error as ProxmoxError {
                switch error {
                case .timedOut, .transport, .httpError(status: 502...504, reason: _):
                    break
                default:
                    throw error
                }
            }
            try await Task.sleep(for: Limits.taskPollInterval)
        }
        throw ProxmoxError.taskStatusUnconfirmed
    }
}
