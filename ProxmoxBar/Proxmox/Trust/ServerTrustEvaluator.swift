import Foundation
import Security

struct ServerTrustEvaluator: Sendable {
    let pinnedFingerprint: String?

    init(pinnedFingerprint: String? = nil) {
        self.pinnedFingerprint = pinnedFingerprint
    }

    func evaluate(_ trust: SecTrust) -> TrustDecision {
        guard let leaf = Self.leafCertificate(of: trust) else {
            return .rejected(.transport("The server presented no certificate."))
        }

        let certificate = ServerCertificate(certificate: leaf)

        guard let pinnedFingerprint else {
            return decideWithoutPin(trust, certificate: certificate)
        }

        guard certificate.fingerprint == pinnedFingerprint else {
            return .rejected(
                .certificateMismatch(
                    expected: pinnedFingerprint,
                    presented: certificate.fingerprint
                )
            )
        }

        if certificate.isExpired {
            return .rejected(.transport("The server's certificate expired."))
        }

        SecTrustSetAnchorCertificates(trust, [leaf] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)
        return SecTrustEvaluateWithError(trust, nil)
            ? .trusted
            : .rejected(.transport("The pinned certificate no longer validates."))
    }

    private func decideWithoutPin(
        _ trust: SecTrust,
        certificate: ServerCertificate
    ) -> TrustDecision {
        if SecTrustEvaluateWithError(trust, nil) {
            return .trusted
        }
        if certificate.isExpired {
            return .rejected(.transport("The server's certificate expired."))
        }
        return .needsApproval(certificate)
    }

    static func leafCertificate(of trust: SecTrust) -> SecCertificate? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            return nil
        }
        return chain.first
    }
}
