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
        case .invalidURL: return "Invalid Server URL"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Received invalid data: \(e.localizedDescription)"
        case .apiError(let c, let m): return "Proxmox API Error (\(c)): \(m)"
        case .invalidCredentials: return "Invalid Credentials / Missing Config"
        }
    }
}

final class URLSessionProxy: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

actor ProxmoxService {
    
    private let session: URLSession
    private let delegateProxy: URLSessionProxy
    
    init() {
        let config = URLSessionConfiguration.default
        self.delegateProxy = URLSessionProxy()
        self.session = URLSession(configuration: config, delegate: delegateProxy, delegateQueue: nil)
    }
    
    func refreshData(url: String, authHeader: String) async throws -> (ProxmoxServiceStatus, [ProxmoxNode], [ProxmoxStorage], [ProxmoxVM]) {
        guard let baseURL = URL(string: url) else { throw ProxmoxError.invalidURL }
        
        let endpoint = baseURL.appendingPathComponent("/api2/json/cluster/resources")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        
        var lastError: Error?
        
        for _ in 1...3 {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ProxmoxError.networkError(NSError(domain: "Invalid Response", code: 0))
                }
                
                if httpResponse.statusCode == 401 {
                    throw ProxmoxError.apiError(401, "Unauthorized (Check Token)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
                    throw ProxmoxError.apiError(httpResponse.statusCode, "Status: \(httpResponse.statusCode) - \(errorMsg)")
                }
                
                let result = try JSONDecoder().decode(ProxmoxResourceResponse.self, from: data)
                
                let vms: [ProxmoxVM] = result.data.compactMap { item in
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
                
                let nodes: [ProxmoxNode] = result.data.compactMap { item in
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
                
                let storages: [ProxmoxStorage] = result.data.compactMap { item in
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
                return (.running, nodes, storages, vms)
                
            } catch {
                lastError = error
                if let proxErr = error as? ProxmoxError, case .apiError = proxErr {
                    throw error
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                continue
            }
        }
        
        if let error = lastError as? ProxmoxError {
            throw error
        } else if let error = lastError {
            throw ProxmoxError.networkError(error)
        } else {
            throw ProxmoxError.networkError(NSError(domain: "Unknown Error", code: -1))
        }
    }
    
    func performNodeAction(node: String, vmid: Int, type: String, action: String, url: String, authHeader: String) async throws -> String {
        guard let baseURL = URL(string: url) else { throw ProxmoxError.invalidURL }
        
        let endpoint = baseURL.appendingPathComponent("/api2/json/nodes/\(node)/\(type)/\(vmid)/status/\(action)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxmoxError.networkError(NSError(domain: "Invalid Response", code: 0))
        }
        
        if httpResponse.statusCode == 401 {
             throw ProxmoxError.apiError(401, "Unauthorized")
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw ProxmoxError.apiError(httpResponse.statusCode, "Action Failed: \(errorMsg)")
        }
        
        do {
            let result = try JSONDecoder().decode(UPIDResponse.self, from: data)
            return result.data
        } catch {
            throw ProxmoxError.decodingError(error)
        }
    }
    
    func waitForTask(node: String, upid: String, url: String, authHeader: String) async throws {
        guard let baseURL = URL(string: url) else { throw ProxmoxError.invalidURL }
        
        let endpoint = baseURL.appendingPathComponent("/api2/json/nodes/\(node)/tasks/\(upid)/status")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        

        // Poll for up to 30 seconds
        for _ in 0..<30 {
            let (data, _) = try await session.data(for: request)
            
            if let task = try? JSONDecoder().decode(TaskStatusResponse.self, from: data).data, task.isStopped {
                guard task.isSuccess else {
                    throw ProxmoxError.apiError(500, "Task failed: \(task.exitstatus ?? "Unknown")")
                }
                return
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        throw ProxmoxError.networkError(NSError(domain: "Task Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Task timed out"]))
    }
}

private struct UPIDResponse: Decodable {
    let data: String
}

private struct TaskStatusResponse: Decodable {
    struct TaskData: Decodable {
        let status: String
        let exitstatus: String?
        
        var isStopped: Bool { status == "stopped" }
        var isSuccess: Bool { exitstatus == "OK" }
    }
    let data: TaskData
}
