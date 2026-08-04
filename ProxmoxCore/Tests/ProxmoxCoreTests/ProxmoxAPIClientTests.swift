import Foundation
import Testing

@testable import ProxmoxCore

@Suite("The Proxmox client, against a stubbed transport", .serialized)
struct ProxmoxAPIClientTests {
    private let url = "https://pve.local:8006"
    private let auth = "PVEAPIToken=user@pve!token=secret"

    private func client(_ handler: @escaping @Sendable (URLRequest) throws -> StubURLProtocol.Response)
        -> ProxmoxAPIClient
    {
        ProxmoxAPIClient(configuration: StubURLProtocol.install(handler))
    }

    @Test("it builds the documented endpoint and sends the token")
    func buildsRequest() async throws {
        let data = try Fixture.data(Fixture.clusterResources)
        let client = client { _ in .ok(data) }

        _ = try await client.snapshot(url: url, authHeader: auth)

        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.url?.path == "/api2/json/cluster/resources")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == auth)
    }

    @Test("a trailing slash on the server URL does not double up")
    func toleratesTrailingSlash() async throws {
        let data = try Fixture.data(Fixture.clusterResources)
        let client = client { _ in .ok(data) }

        _ = try await client.snapshot(url: "https://pve.local:8006/", authHeader: auth)

        #expect(StubURLProtocol.lastRequest?.url?.path == "/api2/json/cluster/resources")
    }

    @Test("a URL without a scheme is refused before any request")
    func refusesSchemelessURL() async throws {
        let client = client { _ in .ok(Data()) }

        await #expect(throws: ProxmoxError.invalidURL) {
            try await client.snapshot(url: "pve.local:8006", authHeader: auth)
        }
        #expect(StubURLProtocol.requestCount == 0)
    }

    @Test("401 becomes an unauthorized error and is not retried")
    func doesNotRetryUnauthorized() async throws {
        let client = client { _ in .status(401, "authentication failure") }

        await #expect(throws: ProxmoxError.unauthorized) {
            try await client.snapshot(url: url, authHeader: auth)
        }
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("a 500 is reported with its body and is not retried")
    func doesNotRetryServerError() async throws {
        let client = client { _ in .status(500, "boom") }

        await #expect(throws: ProxmoxError.apiError(statusCode: 500, message: "boom")) {
            try await client.snapshot(url: url, authHeader: auth)
        }
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("malformed JSON is reported and is not retried")
    func doesNotRetryGarbage() async throws {
        let client = client { _ in .ok(Data("not json".utf8)) }

        await #expect(throws: ProxmoxError.self) {
            try await client.snapshot(url: url, authHeader: auth)
        }
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("a network failure is retried three times")
    func retriesNetworkFailures() async throws {
        let client = client { _ in throw URLError(.cannotConnectToHost) }

        await #expect(throws: ProxmoxError.self) {
            try await client.snapshot(url: url, authHeader: auth)
        }
        #expect(StubURLProtocol.requestCount == 3)
    }

    @Test("a power action posts to the documented endpoint and returns the task id")
    func performsGuestAction() async throws {
        let upid = "UPID:pve:00051234:0123ABCD:65F0A1B2:qmstart:100:root@pam:"
        let client = client { _ in .ok(Data(#"{"data":"\#(upid)"}"#.utf8)) }

        let returned = try await client.performGuestAction(
            .start,
            node: "pve",
            vmid: 100,
            type: "lxc",
            url: url,
            authHeader: auth
        )

        #expect(returned == upid)
        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api2/json/nodes/pve/lxc/100/status/start")
    }

    @Test("a task identifier survives the URL path unchanged")
    func keepsTaskIdentifierIntact() async throws {
        let upid = "UPID:pve:00051234:0123ABCD:65F0A1B2:qmstart:100:root@pam:"
        let client = client { _ in .ok(Data(#"{"data":{"status":"stopped","exitstatus":"OK"}}"#.utf8)) }

        try await client.waitForTask(node: "pve", upid: upid, url: url, authHeader: auth)

        let path = try #require(StubURLProtocol.lastRequest?.url?.absoluteString)
        #expect(path.contains(upid))
    }

    @Test("a failed task reports its exit status")
    func reportsTaskFailure() async throws {
        let client = client { _ in
            .ok(Data(#"{"data":{"status":"stopped","exitstatus":"lock timeout"}}"#.utf8))
        }

        await #expect(throws: ProxmoxError.taskFailed(exitStatus: "lock timeout")) {
            try await client.waitForTask(node: "pve", upid: "UPID:x", url: url, authHeader: auth)
        }
    }
}
