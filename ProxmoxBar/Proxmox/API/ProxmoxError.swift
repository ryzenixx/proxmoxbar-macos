import Foundation

enum ProxmoxError: Error, Hashable, Sendable {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case httpError(status: Int)
    case untrustedCertificate(ServerCertificate, problems: [TrustProblem])
    case certificateMismatch(expected: String, presented: String)
    case transport(String)
    case decoding(String)
    case taskFailed(String)
    case timedOut

    var isRetryable: Bool {
        switch self {
        case .transport, .timedOut: true
        case .invalidURL, .unauthorized, .forbidden, .notFound, .httpError,
            .untrustedCertificate, .certificateMismatch, .decoding, .taskFailed:
            false
        }
    }
}

extension ProxmoxError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The server address is not a valid URL."
        case .unauthorized:
            "The API token was rejected."
        case .forbidden:
            "The API token lacks the permissions this needs."
        case .notFound:
            "The server does not have what was asked for."
        case .httpError(let status):
            "The server answered with HTTP \(status)."
        case .untrustedCertificate:
            "The server presented a certificate that has not been trusted yet."
        case .certificateMismatch:
            "The server's certificate changed since it was trusted."
        case .transport(let reason):
            reason
        case .decoding(let reason):
            "The server's answer could not be read: \(reason)"
        case .taskFailed(let reason):
            reason
        case .timedOut:
            "The server did not answer in time."
        }
    }
}
