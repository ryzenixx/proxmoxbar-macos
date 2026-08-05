import Foundation

enum TrustDecision: Hashable, Sendable {
    case trusted
    case needsApproval(ServerCertificate)
    case rejected(ProxmoxError)
}
