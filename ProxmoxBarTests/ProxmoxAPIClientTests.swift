import Foundation
import Synchronization
import Testing

@testable import ProxmoxBar

@Suite("Proxmox API client")
struct ProxmoxAPIClientTests {
    private func makeServer(host: String) throws -> ProxmoxServer {
        let credentials = try #require(
            ServerCredentials(
                address: "https://\(host):8006",
                tokenIdentifier: "monitor@pve!bar",
                secret: "a-secret"
            )
        )
        return ProxmoxServer(credentials: credentials)
    }

    @Test("The token is sent in the header format Proxmox documents")
    func sendsDocumentedAuthorizationHeader() async throws {
        let host = "auth.test"
        StubURLProtocol.register(host: host) { _ in
            .json(#"{"data":{"version":"9.2.2","release":"9.2","repoid":"abc"}}"#)
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        _ = try await client.version(of: try makeServer(host: host))

        let request = try #require(StubURLProtocol.requests(for: host).first)
        let header = request.value(forHTTPHeaderField: "Authorization")
        #expect(header == "PVEAPIToken=monitor@pve!bar=a-secret")
    }

    @Test("The version endpoint is unwrapped from its data envelope")
    func readsVersion() async throws {
        let host = "version.test"
        StubURLProtocol.register(host: host) { _ in
            .json(#"{"data":{"version":"9.2.2","release":"9.2","repoid":"deadbeef"}}"#)
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let version = try await client.version(of: try makeServer(host: host))

        #expect(version.version == "9.2.2")
        #expect(version.displayName == "Proxmox VE 9.2.2")
    }

    @Test("Cluster resources become a cluster state")
    func readsClusterState() async throws {
        let host = "cluster.test"
        StubURLProtocol.register(host: host) { _ in
            .json(
                """
                {"data":[
                  {"id":"node/pve","type":"node","node":"pve","status":"online"},
                  {"id":"qemu/100","type":"qemu","vmid":100,"node":"pve","status":"running"}
                ]}
                """
            )
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let state = try await client.clusterState(of: try makeServer(host: host))

        #expect(state.nodes.count == 1)
        #expect(state.guests.count == 1)
        let request = try #require(StubURLProtocol.requests(for: host).first)
        #expect(request.url?.path() == "/api2/json/cluster/resources")
    }

    @Test("A rejected token surfaces as unauthorized, not as a decode failure")
    func mapsUnauthorized() async throws {
        let host = "denied.test"
        StubURLProtocol.register(host: host) { _ in .json("{}", status: 401) }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())

        await #expect(throws: ProxmoxError.unauthorized) {
            _ = try await client.version(of: try makeServer(host: host))
        }
    }

    @Test("A token without the right privileges surfaces as forbidden")
    func mapsForbidden() async throws {
        let host = "forbidden.test"
        StubURLProtocol.register(host: host) { _ in .json("{}", status: 403) }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())

        await #expect(throws: ProxmoxError.forbidden) {
            _ = try await client.version(of: try makeServer(host: host))
        }
    }

    @Test("A power action posts to the guest and follows the task to completion")
    func performsActionAndFollowsTask() async throws {
        let host = "action.test"
        StubURLProtocol.register(host: host) { request in
            let path = request.url?.path() ?? ""
            if path.contains("/status/start") {
                return .json(#"{"data":"UPID:pve:0001:start"}"#)
            }
            if path.hasSuffix("/status/current") {
                return .json(#"{"data":{"status":"running"}}"#)
            }
            return .json(
                """
                {"data":{"upid":"UPID:pve:0001:start","node":"pve",
                         "status":"stopped","exitstatus":"OK"}}
                """
            )
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let guest = ProxmoxGuest(
            id: "qemu/100", vmid: 100, kind: .virtualMachine, node: "pve", name: "web",
            status: .stopped, isTemplate: false, lock: nil, tags: [], pool: nil, haState: nil,
            cpu: nil, maxCPUs: nil, memory: nil, maximumMemory: nil, disk: nil,
            maximumDisk: nil, uptime: nil
        )
        try await client.perform(.start, on: guest, of: try makeServer(host: host))

        let requests = StubURLProtocol.requests(for: host)
        #expect(requests.first?.httpMethod == "POST")
        #expect(requests.first?.url?.path() == "/api2/json/nodes/pve/qemu/100/status/start")
        #expect(requests.count == 3)
        #expect(requests.last?.url?.path() == "/api2/json/nodes/pve/qemu/100/status/current")
    }

    @Test("A task that ends badly is reported as a failure")
    func reportsFailedTask() async throws {
        let host = "failtask.test"
        StubURLProtocol.register(host: host) { request in
            if request.url?.path().contains("/status/start") == true {
                return .json(#"{"data":"UPID:pve:0002:start"}"#)
            }
            return .json(
                """
                {"data":{"upid":"UPID:pve:0002:start","node":"pve",
                         "status":"stopped","exitstatus":"cannot start"}}
                """
            )
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let guest = ProxmoxGuest(
            id: "qemu/101", vmid: 101, kind: .virtualMachine, node: "pve", name: nil,
            status: .stopped, isTemplate: false, lock: nil, tags: [], pool: nil, haState: nil,
            cpu: nil, maxCPUs: nil, memory: nil, maximumMemory: nil, disk: nil,
            maximumDisk: nil, uptime: nil
        )
        await #expect(throws: ProxmoxError.taskFailed("cannot start")) {
            try await client.perform(.start, on: guest, of: try makeServer(host: host))
        }
    }
}

@Suite("Server credentials")
struct ServerCredentialsTests {
    @Test("An address without a scheme is refused")
    func refusesSchemelessAddress() {
        #expect(
            ServerCredentials(address: "pve.local:8006", tokenIdentifier: "a", secret: "b") == nil
        )
    }

    @Test("An empty address is refused")
    func refusesEmptyAddress() {
        #expect(ServerCredentials(address: "", tokenIdentifier: "a", secret: "b") == nil)
    }

    @Test("The description never carries the secret")
    func descriptionKeepsTheSecret() throws {
        let credentials = try #require(
            ServerCredentials(
                address: "https://pve.local:8006",
                tokenIdentifier: "monitor@pve!bar",
                secret: "top-secret"
            )
        )
        #expect(credentials.description.contains("top-secret") == false)
    }
}

extension ProxmoxAPIClientTests {
    private func runningGuest() throws -> ProxmoxGuest {
        let json = """
            [{"id":"qemu/109","type":"qemu","vmid":109,"node":"pve","status":"running"}]
            """
        let data = try #require(json.data(using: .utf8))
        let resources = try JSONDecoder().decode([ClusterResource].self, from: data)
        return try #require(ClusterState(resources: resources).guests.first)
    }

    @Test("The task identifier is percent encoded exactly once")
    func encodesTaskIdentifierOnce() async throws {
        let host = "upid.test"
        let upid = "UPID:pve:0012A3B4:00ABCDEF:66B1C2D3:qmshutdown:109:monitor@pve!bar:"
        StubURLProtocol.register(host: host) { request in
            if request.httpMethod == "POST" {
                return .json(#"{"data":"\#(upid)"}"#)
            }
            return .json(
                #"{"data":{"upid":"x","node":"pve","status":"stopped","exitstatus":"OK"}}"#)
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        try await client.perform(.shutdown, on: try runningGuest(), of: try makeServer(host: host))

        let poll = try #require(
            StubURLProtocol.requests(for: host).first { $0.httpMethod == "GET" }
        )
        let path = try #require(poll.url?.absoluteString)
        #expect(path.contains("%3A"))
        #expect(path.contains("%253A") == false)
    }

    @Test("The action is posted to the endpoint Proxmox documents")
    func postsActionToDocumentedPath() async throws {
        let host = "postaction.test"
        StubURLProtocol.register(host: host) { request in
            if request.httpMethod == "POST" {
                return .json(#"{"data":"UPID:pve:1:2:3:qmshutdown:109:root@pam:"}"#)
            }
            return .json(
                #"{"data":{"upid":"x","node":"pve","status":"stopped","exitstatus":"OK"}}"#)
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        try await client.perform(.shutdown, on: try runningGuest(), of: try makeServer(host: host))

        let post = try #require(
            StubURLProtocol.requests(for: host).first { $0.httpMethod == "POST" }
        )
        #expect(post.url?.path() == "/api2/json/nodes/pve/qemu/109/status/shutdown")
        #expect(
            post.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test("A refused request carries the reason Proxmox gave")
    func surfacesServerReason() async throws {
        let host = "refused.test"
        StubURLProtocol.register(host: host) { _ in
            .json(#"{"data":null,"errors":{"vmid":"VM 109 is not running"}}"#, status: 500)
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())

        await #expect(throws: ProxmoxError.self) {
            try await client.clusterState(of: try makeServer(host: host))
        }
        do {
            _ = try await client.clusterState(of: try makeServer(host: host))
        } catch let error as ProxmoxError {
            #expect(error.errorDescription?.contains("VM 109 is not running") == true)
        }
    }
}

extension ProxmoxAPIClientTests {
    @Test("A shutdown waits for the guest to actually reach a stopped state")
    func waitsForGuestToSettle() async throws {
        let host = "settle.test"
        let polls = Mutex<Int>(0)
        StubURLProtocol.register(host: host) { request in
            let path = request.url?.path() ?? ""
            if request.httpMethod == "POST" {
                return .json(#"{"data":"UPID:pve:1:2:3:vzshutdown:109:root@pam:"}"#)
            }
            if path.hasSuffix("/status/current") {
                let seen = polls.withLock { count -> Int in
                    count += 1
                    return count
                }
                return .json(#"{"data":{"status":"\#(seen < 3 ? "running" : "stopped")"}}"#)
            }
            return .json(
                #"{"data":{"upid":"x","node":"pve","status":"stopped","exitstatus":"OK"}}"#
            )
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let guest = ProxmoxGuest(
            id: "lxc/109", vmid: 109, kind: .container, node: "pve", name: "portainer",
            status: .running, isTemplate: false, lock: nil, tags: [], pool: nil, haState: nil,
            cpu: nil, maxCPUs: nil, memory: nil, maximumMemory: nil, disk: nil,
            maximumDisk: nil, uptime: nil
        )
        try await client.perform(.shutdown, on: guest, of: try makeServer(host: host))

        #expect(polls.withLock { $0 } == 3)
    }

    @Test("A restart does not wait for a settled state because it ends where it began")
    func restartSkipsSettling() async throws {
        let host = "restart.test"
        StubURLProtocol.register(host: host) { request in
            if request.httpMethod == "POST" {
                return .json(#"{"data":"UPID:pve:1:2:3:vzreboot:109:root@pam:"}"#)
            }
            return .json(
                #"{"data":{"upid":"x","node":"pve","status":"stopped","exitstatus":"OK"}}"#
            )
        }
        let client = ProxmoxAPIClient(configuration: StubURLProtocol.configuration())
        let guest = ProxmoxGuest(
            id: "lxc/109", vmid: 109, kind: .container, node: "pve", name: "portainer",
            status: .running, isTemplate: false, lock: nil, tags: [], pool: nil, haState: nil,
            cpu: nil, maxCPUs: nil, memory: nil, maximumMemory: nil, disk: nil,
            maximumDisk: nil, uptime: nil
        )
        try await client.perform(.reboot, on: guest, of: try makeServer(host: host))

        let statusCalls = StubURLProtocol.requests(for: host).filter {
            $0.url?.path().hasSuffix("/status/current") == true
        }
        #expect(statusCalls.isEmpty)
    }
}
