import Foundation
import Testing

@testable import ProxmoxCore

@Suite("Single-guest status and server version")
struct GuestStatusTests {
    private let url = "https://pve.local:8006"
    private let auth = "PVEAPIToken=user@pve!token=secret"

    private func transport(_ body: String) -> (ProxmoxAPIClient, StubTransport) {
        let transport = StubTransport { _ in .ok(body) }
        return (ProxmoxAPIClient(configuration: transport.configuration), transport)
    }

    @Test("a container status is decoded from a real payload")
    func decodesContainerStatus() async throws {
        let payload = """
            {"data":{"vmid":100,"name":"guest-01","status":"stopped","type":"lxc",
            "cpu":0,"cpus":2,"disk":0,"diskread":0,"diskwrite":0,"ha":{"managed":0},
            "maxdisk":4294967296,"maxmem":1073741824,"maxswap":536870912,"mem":0,
            "netin":0,"netout":0,"swap":0,"tags":"docker","uptime":0}}
            """
        let (client, _) = transport(payload)
        let status = try await client.guestStatus(
            node: "pve",
            vmid: 100,
            type: "lxc",
            url: url,
            authHeader: auth
        )

        #expect(status.vmid == 100)
        #expect(status.status == "stopped")
        #expect(status.isRunning == false)
        #expect(status.cpus == 2)
        #expect(status.maxswap == 536_870_912)
        #expect(status.tags == ["docker"])
        #expect(status.isManagedByHA == false)
        #expect(status.hasGuestAgent == false)
    }

    @Test("a virtual machine status carries the agent flag and qmp status")
    func decodesVirtualMachineStatus() async throws {
        let payload = """
            {"data":{"vmid":106,"name":"guest-02","status":"stopped","qmpstatus":"stopped",
            "agent":1,"cpu":0,"cpus":8,"disk":0,"ha":{"managed":0},"maxdisk":214748364800,
            "maxmem":17179869184,"mem":0,"memhost":0,"netin":0,"netout":0,"uptime":0}}
            """
        let (client, _) = transport(payload)
        let status = try await client.guestStatus(
            node: "pve",
            vmid: 106,
            type: "qemu",
            url: url,
            authHeader: auth
        )

        #expect(status.hasGuestAgent)
        #expect(status.qmpStatus == "stopped")
        #expect(status.hostMemory == 0)
        #expect(status.cpus == 8)
    }

    @Test("high availability is read from a nested object, not a string")
    func readsNestedHighAvailability() async throws {
        let (client, _) = transport(#"{"data":{"vmid":1,"status":"running","ha":{"managed":1}}}"#)
        let status = try await client.guestStatus(
            node: "pve",
            vmid: 1,
            type: "lxc",
            url: url,
            authHeader: auth
        )

        #expect(status.isManagedByHA)
    }

    @Test("it targets the documented per-guest endpoint")
    func buildsGuestStatusEndpoint() async throws {
        let (client, transport) = transport(#"{"data":{"vmid":1,"status":"running"}}"#)
        _ = try await client.guestStatus(
            node: "pve",
            vmid: 42,
            type: "qemu",
            url: url,
            authHeader: auth
        )

        let request = try #require(transport.lastRequest)
        #expect(request.url?.path == "/api2/json/nodes/pve/qemu/42/status/current")
        #expect(request.httpMethod == "GET")
    }

    @Test("the version endpoint answers with the release")
    func decodesVersion() async throws {
        let payload = #"{"data":{"repoid":"b9984c6d90a4bd80","release":"9.2","version":"9.2.2"}}"#
        let (client, transport) = transport(payload)
        let version = try await client.version(url: url, authHeader: auth)

        #expect(version.version == "9.2.2")
        #expect(version.release == "9.2")
        #expect(version.console == nil)
        #expect(transport.lastRequest?.url?.path == "/api2/json/version")
    }

    @Test("a bad token on the version endpoint is reported as unauthorized")
    func rejectsBadToken() async throws {
        let stub = StubTransport { _ in .status(401, "authentication failure") }
        let client = ProxmoxAPIClient(configuration: stub.configuration)

        await #expect(throws: ProxmoxError.unauthorized) {
            try await client.version(url: url, authHeader: auth)
        }
    }
}
