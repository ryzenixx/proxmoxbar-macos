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

    public init() {
        trustDelegate = ServerTrustDelegate()
        session = URLSession(
            configuration: .default,
            delegate: trustDelegate,
            delegateQueue: nil
        )
    }

    public func snapshot(url: String, authHeader: String) async throws -> ClusterSnapshot {
        let request = try makeRequest(
            url: url,
            path: "/api2/json/cluster/resources",
            method: "GET",
            authHeader: authHeader
        )

        var lastError: Error?

        for _ in 1...Limits.snapshotAttempts {
            do {
                let data = try await send(request)
                let response = try decode(ClusterResourcesResponse.self, from: data)
                return ClusterSnapshot(response.data)
            } catch let error as ProxmoxError {
                if case .apiError = error { throw error }
                if case .unauthorized = error { throw error }
                lastError = error
                try? await Task.sleep(for: Limits.retryDelay)
            }
        }

        throw lastError ?? ProxmoxError.networkError("Unknown error")
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
            method: "POST",
            authHeader: authHeader
        )

        let data = try await send(request)
        return try decode(TaskIdentifierResponse.self, from: data).data
    }

    public func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws {
        let request = try makeRequest(
            url: url,
            path: "/api2/json/nodes/\(node)/tasks/\(upid)/status",
            method: "GET",
            authHeader: authHeader
        )

        for _ in 0..<Limits.taskPollAttempts {
            let data = try await send(request)
            guard let task = try? decode(TaskStatusResponse.self, from: data).data, task.hasStopped else {
                try? await Task.sleep(for: Limits.taskPollInterval)
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
    func makeRequest(url: String, path: String, method: String, authHeader: String) throws -> URLRequest {
        guard let baseURL = URL(string: url) else {
            throw ProxmoxError.invalidURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = Limits.requestTimeout
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }

    func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
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
