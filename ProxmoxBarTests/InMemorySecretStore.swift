import Foundation
import Synchronization

@testable import ProxmoxBar

final class InMemorySecretStore: SecretStore {
    private let secrets = Mutex<[UUID: String]>([:])

    func secret(for identifier: UUID) throws -> String? {
        secrets.withLock { $0[identifier] }
    }

    func store(_ secret: String, for identifier: UUID) throws {
        secrets.withLock { $0[identifier] = secret }
    }

    func removeSecret(for identifier: UUID) throws {
        secrets.withLock { $0[identifier] = nil }
    }

    var count: Int {
        secrets.withLock { $0.count }
    }
}
