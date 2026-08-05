import Foundation

enum TrustProblem: Hashable, Sendable {
    case untrustedIssuer
    case hostnameMismatch
    case expired(Date)
    case notYetValid(Date)
    case other(String)

    var summary: String {
        switch self {
        case .untrustedIssuer:
            "Issued by an authority your Mac does not know."
        case .hostnameMismatch:
            "Issued for a different address than the one you entered."
        case .expired(let date):
            "Expired on \(Self.formatted(date))."
        case .notYetValid(let date):
            "Not valid until \(Self.formatted(date))."
        case .other(let reason):
            reason
        }
    }

    var isExpected: Bool {
        switch self {
        case .untrustedIssuer, .hostnameMismatch: true
        case .expired, .notYetValid, .other: false
        }
    }

    private static func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
