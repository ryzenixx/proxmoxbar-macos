import CryptoKit
import Foundation
import Security

struct ServerCertificate: Hashable, Sendable {
    let fingerprint: String
    let subject: String
    let issuer: String?
    let expiry: Date?

    var isExpired: Bool {
        guard let expiry else { return false }
        return expiry < Date()
    }
}

extension ServerCertificate {
    init(certificate: SecCertificate) {
        let data = SecCertificateCopyData(certificate) as Data
        self.fingerprint = Self.fingerprint(of: data)
        self.subject = (SecCertificateCopySubjectSummary(certificate) as String?) ?? "Unknown"
        self.issuer = Self.value(of: kSecOIDX509V1IssuerName, in: certificate) as? String
        self.expiry = Self.expiry(of: certificate)
    }

    static func fingerprint(of derData: Data) -> String {
        SHA256.hash(data: derData)
            .map { String(format: "%02X", $0) }
            .joined(separator: ":")
    }

    private static func value(of oid: CFString, in certificate: SecCertificate) -> Any? {
        guard
            let values = SecCertificateCopyValues(certificate, [oid] as CFArray, nil)
                as? [CFString: Any],
            let entry = values[oid] as? [CFString: Any]
        else { return nil }
        return entry[kSecPropertyKeyValue]
    }

    private static func expiry(of certificate: SecCertificate) -> Date? {
        guard let raw = value(of: kSecOIDX509V1ValidityNotAfter, in: certificate) as? Double
        else { return nil }
        return Date(timeIntervalSinceReferenceDate: raw)
    }
}
