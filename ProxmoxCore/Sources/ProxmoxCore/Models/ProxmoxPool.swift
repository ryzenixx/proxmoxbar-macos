import Foundation

public struct ProxmoxPool: Identifiable, Codable, Hashable, Sendable {
    public let pool: String

    public init(pool: String) {
        self.pool = pool
    }

    public var id: String { pool }
}
