import Foundation

public actor ProxmoxAPIClient: ProxmoxAPI {
    private enum Limits {
        static let requestTimeout: TimeInterval = 10
        static let snapshotAttempts = 3
        static let retryDelay: Duration = .milliseconds(500)
        static let taskPollInterval: Duration = .seconds(1)
        static let taskPollAttempts = 30
    }

    private let session: URLSession
    private let trustDelegate: ServerTrustDelegate

    public init(configuration: URLSessionConfiguration = .default) {
        trustDelegate = ServerTrustDelegate()
        session = URLSession(
            configuration: configuration,
            delegate: trustDelegate,
            delegateQueue: nil
        )
    }

    public func snapshot(url: String, authHeader: String) async throws -> ClusterSnapshot {
        let request = try makeRequest(
            url: url,
            path: "/api2/json/cluster/resources",
            method: .get,
            authHeader: authHeader
        )

        let data = try await sendWithRetries(request)
        return ClusterSnapshot(try decode(ClusterResourcesResponse.self, from: data).data)
    }

    public func performGuestAction(
        _ action: GuestAction,
        node: String,
        vmid: Int,
        type: String,
        url: String,
        authHeader: String
    ) async throws -> String {
        let request = try makeRequest(
            url: url,
            path: "/api2/json/nodes/\(node)/\(type)/\(vmid)/status/\(action.rawValue)",
            method: .post,
            authHeader: authHeader
        )

        let data = try await send(request)
        return try decode(TaskIdentifierResponse.self, from: data).data
    }

    public func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws {
        let request = try makeRequest(
            url: url,
            path: "/api2/json/nodes/\(node)/tasks/\(upid)/status",
            method: .get,
            authHeader: authHeader
        )

        for _ in 0..<Limits.taskPollAttempts {
            let data = try await send(request)

            guard let task = try? decode(TaskStatusResponse.self, from: data).data, task.hasStopped else {
                try await Task.sleep(for: Limits.taskPollInterval)
                continue
            }

            guard task.hasSucceeded else {
                throw ProxmoxError.taskFailed(exitStatus: task.exitstatus ?? "unknown")
            }
            return
        }

        throw ProxmoxError.taskTimedOut
    }
}

private extension ProxmoxAPIClient {
    func makeRequest(url: String, path: String, method: HTTPMethod, authHeader: String) throws -> URLRequest {
        guard let baseURL = URL(string: url),
            let scheme = baseURL.scheme?.lowercased(),
            scheme == "https" || scheme == "http",
            let host = baseURL.host,
            !host.isEmpty
        else {
            throw ProxmoxError.invalidURL
        }

        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = Limits.requestTimeout
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }

    func sendWithRetries(_ request: URLRequest) async throws -> Data {
        var attempt = 1

        while true {
            do {
                return try await send(request)
            } catch let error as ProxmoxError where error.isRetryable && attempt < Limits.snapshotAttempts {
                attempt += 1
                try await Task.sleep(for: Limits.retryDelay)
            }
        }
    }

    func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw ProxmoxError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProxmoxError.networkError("The response was not HTTP.")
        }

        if http.statusCode == 401 {
            throw ProxmoxError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw ProxmoxError.apiError(statusCode: http.statusCode, message: body)
        }

        return data
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProxmoxError.decodingError(error.localizedDescription)
        }
    }
}
