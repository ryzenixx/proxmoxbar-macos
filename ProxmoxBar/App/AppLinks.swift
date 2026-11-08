import Foundation

enum AppLinks {
    static let repository = URL(
        string: "https://github.com/ryzenixx/proxmoxbar-macos"
    )
    static let issues = repository?.appending(path: "issues")
    static let support = URL(string: "https://ko-fi.com/ryzenixx")
    static let tokenGuide = repository.flatMap {
        URL(string: "#create-a-restricted-api-token", relativeTo: $0)?.absoluteURL
    }
}
