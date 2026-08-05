import Foundation

struct ServerCredentials: Hashable, Sendable {
    let baseURL: URL
    let tokenIdentifier: String
    let secret: String

    var authorizationHeader: String {
        "PVEAPIToken=\(tokenIdentifier)=\(secret)"
    }

    init?(address: String, tokenIdentifier: String, secret: String) {
        guard let url = URL(string: address.trimmingCharacters(in: .whitespaces)),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http",
            let host = url.host(),
            host.isEmpty == false
        else { return nil }

        self.baseURL = url
        self.tokenIdentifier = tokenIdentifier.trimmingCharacters(in: .whitespaces)
        self.secret = secret.trimmingCharacters(in: .whitespaces)
    }
}

extension ServerCredentials: CustomStringConvertible {
    var description: String {
        "ServerCredentials(host: \(baseURL.host() ?? "?"))"
    }
}
