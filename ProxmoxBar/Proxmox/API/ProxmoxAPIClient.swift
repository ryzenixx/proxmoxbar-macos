import Foundation

actor ProxmoxAPIClient: ProxmoxAPI {
    private enum Limits {
        static let requestTimeout: TimeInterval = 10
        static let taskPollInterval: Duration = .seconds(1)
        static let taskPollAttempts = 30
        static let settlePollAttempts = 20
    }

    private struct Transport {
        let session: URLSession
        let delegate: ProxmoxSessionDelegate
    }

    private let configuration: URLSessionConfiguration
    private var transports: [ProxmoxServer: Transport] = [:]

    init(configuration: URLSessionConfiguration = .ephemeral) {
        configuration.timeoutIntervalForRequest = Limits.requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.configuration = configuration
    }

    func version(of server: ProxmoxServer) async throws -> ServerVersion {
        let payload: VersionPayload = try await get(["version"], from: server)
        return ServerVersion(
            version: payload.version,
            release: payload.release,
            repositoryID: payload.repoid
        )
    }

    func clusterState(of server: ProxmoxServer) async throws -> ClusterState {
        let resources: [ClusterResource] = try await get(
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
        let upid: String = try await post(
            [
                "nodes", guest.node, guest.kind.pathComponent, String(guest.vmid),
                "status", action.pathComponent,
            ],
            to: server
        )
        try await waitForTask(upid, on: guest.node, of: server)
        if let settled = action.settledStatus {
            try await waitUntilGuestSettles(into: settled, guest: guest, of: server)
        }
    }

    private func waitUntilGuestSettles(
        into expected: GuestStatus,
        guest: ProxmoxGuest,
        of server: ProxmoxServer
    ) async throws {
        let segments = [
            "nodes", guest.node, guest.kind.pathComponent, String(guest.vmid),
            "status", "current",
        ]
        for _ in 0..<Limits.settlePollAttempts {
            let current: GuestStatusPayload = try await get(segments, from: server)
            if GuestStatus(rawValue: current.status) == expected { return }
            try await Task.sleep(for: Limits.taskPollInterval)
        }
    }

    private func get<Payload: Decodable & Sendable>(
        _ segments: [String],
        from server: ProxmoxServer
    ) async throws -> Payload {
        let request = try makeRequest(segments, method: "GET", server: server)
        let data = try await send(request, to: server)
        return try decode(ProxmoxResponse<Payload>.self, from: data).data
    }

    private func post<Payload: Decodable & Sendable>(
        _ segments: [String],
        to server: ProxmoxServer
    ) async throws -> Payload {
        var request = try makeRequest(segments, method: "POST", server: server)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()
        let data = try await send(request, to: server)
        return try decode(ProxmoxResponse<Payload>.self, from: data).data
    }

    private func waitForTask(
        _ upid: String,
        on node: String,
        of server: ProxmoxServer
    ) async throws {
        let segments = ["nodes", node, "tasks", upid, "status"]

        for _ in 0..<Limits.taskPollAttempts {
            let status: TaskStatusPayload = try await get(segments, from: server)
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

    private func makeRequest(
        _ segments: [String],
        method: String,
        server: ProxmoxServer
    ) throws -> URLRequest {
        var request = URLRequest(url: try url(for: segments, of: server))
        request.httpMethod = method
        request.setValue(
            server.credentials.authorizationHeader,
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func url(for segments: [String], of server: ProxmoxServer) throws -> URL {
        var components = URLComponents(
            url: server.credentials.baseURL,
            resolvingAgainstBaseURL: false
        )
        let escaped = segments.map {
            $0.addingPercentEncoding(withAllowedCharacters: .proxmoxPathSegment) ?? $0
        }
        components?.percentEncodedPath = "/api2/json/" + escaped.joined(separator: "/")
        guard let url = components?.url else { throw ProxmoxError.invalidURL }
        return url
    }

    private func send(_ request: URLRequest, to server: ProxmoxServer) async throws -> Data {
        let transport = transport(for: server)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.session.data(for: request)
        } catch let error as URLError {
            if let rejection = transport.delegate.takeRejection() {
                throw rejection
            }
            if error.code == .cancelled {
                throw CancellationError()
            }
            if error.code == .timedOut {
                throw ProxmoxError.timedOut
            }
            throw ProxmoxError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProxmoxError.transport("The server sent a response that was not HTTP.")
        }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw ProxmoxError.unauthorized
        case 403: throw ProxmoxError.forbidden
        case 404: throw ProxmoxError.notFound
        default:
            throw ProxmoxError.httpError(
                status: http.statusCode,
                reason: try? JSONDecoder()
                    .decode(ProxmoxFailurePayload.self, from: data)
                    .reason
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProxmoxError.decoding(error.localizedDescription)
        }
    }

    private func transport(for server: ProxmoxServer) -> Transport {
        if let existing = transports[server] { return existing }
        let delegate = ProxmoxSessionDelegate(
            evaluator: ServerTrustEvaluator(pinnedFingerprint: server.pinnedFingerprint)
        )
        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
        let transport = Transport(session: session, delegate: delegate)
        transports[server] = transport
        return transport
    }
}
