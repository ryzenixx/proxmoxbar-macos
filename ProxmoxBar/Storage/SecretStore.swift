import Foundation

protocol SecretStore: Sendable {
    func secret(for identifier: UUID) throws -> String?
    func store(_ secret: String, for identifier: UUID) throws
    func removeSecret(for identifier: UUID) throws
}

enum SecretStoreError: Error, Hashable, Sendable {
    case unwritable(OSStatus)
    case unreadable(OSStatus)
    case corrupted
}

extension SecretStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unwritable(let status):
            "The token could not be saved to the keychain (\(status))."
        case .unreadable(let status):
            "The token could not be read from the keychain (\(status))."
        case .corrupted:
            "The stored token is not readable text."
        }
    }
}
