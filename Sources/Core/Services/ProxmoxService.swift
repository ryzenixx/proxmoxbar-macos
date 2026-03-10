import Foundation

enum ProxmoxServiceStatus {
    case running
    case stopped
    case loading(String)
    case error(String)
}

enum ProxmoxError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(Int, String)
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Received invalid data: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "Proxmox API Error (\(statusCode)): \(message)"
        case .invalidCredentials:
            return "Invalid Credentials / Missing Config"
        }
    }
}

final class InsecureServerTrustDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

actor ProxmoxService {
    private enum Constants {
        static let requestTimeout: TimeInterval = 10
        static let refreshRetries = 3
        static let refreshRetryDelayNanoseconds: UInt64 = 500_000_000
        static let taskPollingIntervalNanoseconds: UInt64 = 1_000_000_000
        static let taskPollingRetries = 30
    }

    private let session: URLSession
    private let delegateProxy: InsecureServerTrustDelegate

    init() {
        let configuration = URLSessionConfiguration.default
        delegateProxy = InsecureServerTrustDelegate()
        session = URLSession(configuration: configuration, delegate: delegateProxy, delegateQueue: nil)
    }

    func refreshData(url: String, authHeader: String) async throws -> (ProxmoxServiceStatus, [ProxmoxNode], [ProxmoxStorage], [ProxmoxVM]) {
        guard let baseURL = URL(string: url) else {
            throw ProxmoxError.invalidURL
        }

        let endpoint = baseURL.appendingPathComponent("/api2/json/cluster/resources")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = Constants.requestTimeout
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        var lastError: Error?

        for _ in 1...Constants.refreshRetries {
            do {
                let (data, response) = try await session.data(for: request)
                try validateHTTPResponse(response, data: data)

                let decoded = try JSONDecoder().decode(ProxmoxResourceResponse.self, from: data)
                let resources = decodeResources(decoded.data)
                return (.running, resources.nodes, resources.storages, resources.vms)
            } catch {
                lastError = error

                if let proxmoxError = error as? ProxmoxError, case .apiError = proxmoxError {
                    throw error
                }
                try? await Task.sleep(nanoseconds: Constants.refreshRetryDelayNanoseconds)
            }
        }

        if let proxmoxError = lastError as? ProxmoxError {
            throw proxmoxError
        }
        if let error = lastError {
            throw ProxmoxError.networkError(error)
        }
        throw ProxmoxError.networkError(NSError(domain: "Unknown Error", code: -1))
    }

    func performNodeAction(
        node: String,
        vmid: Int,
        type: String,
        action: String,
        url: String,
        authHeader: String
    ) async throws -> String {
        guard let baseURL = URL(string: url) else {
            throw ProxmoxError.invalidURL
        }

        let endpoint = baseURL.appendingPathComponent("/api2/json/nodes/\(node)/\(type)/\(vmid)/status/\(action)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response, data: data)

        do {
            return try JSONDecoder().decode(UPIDResponse.self, from: data).data
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }

    func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws {
        guard let baseURL = URL(string: url) else {
            throw ProxmoxError.invalidURL
        }

        let endpoint = baseURL.appendingPathComponent("/api2/json/nodes/\(node)/tasks/\(upid)/status")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        for _ in 0..<Constants.taskPollingRetries {
            let (data, _) = try await session.data(for: request)

            if let task = try? JSONDecoder().decode(TaskStatusResponse.self, from: data).data, task.isStopped {
                guard task.isSuccess else {
                    throw ProxmoxError.apiError(500, "Task failed: \(task.exitstatus ?? "Unknown")")
                }
                return
            }

            try? await Task.sleep(nanoseconds: Constants.taskPollingIntervalNanoseconds)
        }

        throw ProxmoxError.networkError(
            NSError(
                domain: "Task Timeout",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Task timed out"]
            )
        )
    }
}

private extension ProxmoxService {
    typealias DecodedResources = (nodes: [ProxmoxNode], storages: [ProxmoxStorage], vms: [ProxmoxVM])

    func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxmoxError.networkError(NSError(domain: "Invalid Response", code: 0))
        }

        if httpResponse.statusCode == 401 {
            throw ProxmoxError.apiError(401, "Unauthorized (Check Token)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorPayload = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw ProxmoxError.apiError(httpResponse.statusCode, "Status: \(httpResponse.statusCode) - \(errorPayload)")
        }
    }

    func decodeResources(_ rawResources: [ProxmoxRawResource]) -> DecodedResources {
        let vms = rawResources
            .compactMap { item -> ProxmoxVM? in
                guard let vmid = item.vmid,
                      let name = item.name,
                      let status = item.status,
                      let type = item.type,
                      let node = item.node,
                      (type == "qemu" || type == "lxc") else {
                    return nil
                }

                return ProxmoxVM(
                    vmid: vmid,
                    name: name,
                    status: status,
                    type: type,
                    node: node,
                    cpu: item.cpu,
                    maxcpu: item.maxcpu,
                    mem: item.mem,
                    maxmem: item.maxmem,
                    disk: item.disk,
                    maxdisk: item.maxdisk
                )
            }
            .sorted { $0.vmid < $1.vmid }

        let nodes = rawResources.compactMap { item -> ProxmoxNode? in
            guard let type = item.type,
                  type == "node",
                  let node = item.node,
                  let status = item.status else {
                return nil
            }

            return ProxmoxNode(
                node: node,
                status: status,
                cpu: item.cpu,
                maxcpu: item.maxcpu,
                mem: item.mem,
                maxmem: item.maxmem,
                disk: item.disk,
                maxdisk: item.maxdisk
            )
        }

        let storages = rawResources
            .compactMap { item -> ProxmoxStorage? in
                guard let type = item.type,
                      type == "storage",
                      let storage = item.storage,
                      let node = item.node,
                      let status = item.status else {
                    return nil
                }

                return ProxmoxStorage(
                    storage: storage,
                    node: node,
                    status: status,
                    disk: item.disk,
                    maxdisk: item.maxdisk,
                    type: item.plugintype,
                    content: item.content
                )
            }
            .sorted {
                if $0.diskUsage != $1.diskUsage {
                    return $0.diskUsage > $1.diskUsage
                }
                return $0.storage < $1.storage
            }

        return (nodes, storages, vms)
    }
}
