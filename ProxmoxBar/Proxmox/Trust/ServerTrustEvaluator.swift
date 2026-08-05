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

        if SecTrustEvaluateWithError(trust, nil) {
            return .trusted
        }

        let problems = Self.diagnose(trust, leaf: leaf, certificate: certificate)

        guard let pinnedFingerprint else {
            return .needsApproval(certificate, problems: problems)
        }
        guard certificate.fingerprint == pinnedFingerprint else {
            return .rejected(
                .certificateMismatch(
                    expected: pinnedFingerprint,
                    presented: certificate.fingerprint
                )
            )
        }
        let unexpected = problems.filter { $0.isExpected == false }
        guard unexpected.isEmpty else {
            return .rejected(
                .transport(unexpected.map(\.summary).joined(separator: " "))
            )
        }
        return .trusted
    }

    private static func diagnose(
        _ trust: SecTrust,
        leaf: SecCertificate,
        certificate: ServerCertificate
    ) -> [TrustProblem] {
        SecTrustSetAnchorCertificates(trust, [leaf] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)

        if SecTrustEvaluateWithError(trust, nil) {
            return [.untrustedIssuer]
        }

        SecTrustSetPolicies(trust, SecPolicyCreateBasicX509())
        if SecTrustEvaluateWithError(trust, nil) {
            return [.untrustedIssuer, .hostnameMismatch]
        }

        var problems: [TrustProblem] = [.untrustedIssuer]
        let now = Date()
        if let notBefore = certificate.notBefore, notBefore > now {
            problems.append(.notYetValid(notBefore))
        }
        if let expiry = certificate.expiry, expiry < now {
            problems.append(.expired(expiry))
        }
        if problems.count == 1 {
            var error: CFError?
            _ = SecTrustEvaluateWithError(trust, &error)
            let reason = (error as Error?)?.localizedDescription
            problems.append(.other(reason ?? "The certificate did not validate."))
        }
        return problems
    }

    static func leafCertificate(of trust: SecTrust) -> SecCertificate? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            return nil
        }
        return chain.first
    }
}
