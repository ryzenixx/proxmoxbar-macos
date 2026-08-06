import Foundation
import Synchronization

@testable import ProxmoxBar

final class StubProxmoxAPI: ProxmoxAPI, Sendable {
    private let outcome = Mutex<Result<ClusterState, any Error>>(.success(.empty))
    private let actionOutcome = Mutex<(any Error)?>(nil)
    private let calls = Mutex<Int>(0)
    private let performed = Mutex<[GuestAction]>([])

    var callCount: Int {
        calls.withLock { $0 }
    }

    var performedActions: [GuestAction] {
        performed.withLock { $0 }
    }

    func returns(_ state: ClusterState) {
        outcome.withLock { $0 = .success(state) }
    }

    func fails(with error: any Error) {
        outcome.withLock { $0 = .failure(error) }
    }

    func failsActions(with error: (any Error)?) {
        actionOutcome.withLock { $0 = error }
    }

    func version(of server: ProxmoxServer) async throws -> ServerVersion {
        ServerVersion(version: "8.4.1", release: "8.4", repositoryID: "pve-no-subscription")
    }

    func clusterState(of server: ProxmoxServer) async throws -> ClusterState {
        calls.withLock { $0 += 1 }
        return try outcome.withLock { $0 }.get()
    }

    func perform(
        _ action: GuestAction,
        on guest: ProxmoxGuest,
        of server: ProxmoxServer
    ) async throws {
        performed.withLock { $0.append(action) }
        if let error = actionOutcome.withLock({ $0 }) {
            throw error
        }
    }
}
