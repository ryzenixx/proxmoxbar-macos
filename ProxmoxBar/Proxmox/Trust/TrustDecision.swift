import Foundation

enum TrustDecision: Hashable, Sendable {
    case trusted
    case needsApproval(ServerCertificate, problems: [TrustProblem])
    case rejected(ProxmoxError)
}
