import Foundation
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
        #expect(requests.count == 2)
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
