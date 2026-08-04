import Foundation

public struct ServerVersion: Hashable, Sendable {
    public let version: String
    public let release: String?
    public let repositoryId: String?
    public let console: String?

    public init(version: String, release: String? = nil, repositoryId: String? = nil, console: String? = nil)
    {
        self.version = version
        self.release = release
        self.repositoryId = repositoryId
        self.console = console
    }
}
