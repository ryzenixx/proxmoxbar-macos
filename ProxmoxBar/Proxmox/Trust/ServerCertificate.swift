import CryptoKit
import Foundation
import Security

struct ServerCertificate: Hashable, Sendable {
    let fingerprint: String
    let subject: String
    let issuer: String?
    let notBefore: Date?
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
        self.issuer = Self.commonName(of: kSecOIDX509V1IssuerName, in: certificate)
        self.notBefore = Self.date(kSecOIDX509V1ValidityNotBefore, of: certificate)
        self.expiry = Self.date(kSecOIDX509V1ValidityNotAfter, of: certificate)
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

    private static func commonName(of oid: CFString, in certificate: SecCertificate) -> String? {
        guard let components = value(of: oid, in: certificate) as? [[CFString: Any]] else {
            return nil
        }
        let named = components.first { entry in
            (entry[kSecPropertyKeyLabel] as? String) == (kSecOIDCommonName as String)
        }
        return (named ?? components.last)?[kSecPropertyKeyValue] as? String
    }

    private static func date(_ oid: CFString, of certificate: SecCertificate) -> Date? {
        guard let raw = value(of: oid, in: certificate) as? Double else { return nil }
        return Date(timeIntervalSinceReferenceDate: raw)
    }
}
