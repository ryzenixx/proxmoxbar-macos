import Foundation
import Security

struct KeychainSecretStore: SecretStore {
    let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.proxmoxbar.app") {
        self.service = service
    }

    func secret(for identifier: UUID) throws -> String? {
        var query = baseQuery(for: identifier)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                let secret = String(data: data, encoding: .utf8)
            else { throw SecretStoreError.corrupted }
            return secret
        case errSecItemNotFound:
            return nil
        default:
            throw SecretStoreError.unreadable(status)
        }
    }

    func store(_ secret: String, for identifier: UUID) throws {
        let data = Data(secret.utf8)
        let query = baseQuery(for: identifier)

        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw SecretStoreError.unwritable(updateStatus)
        }

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecretStoreError.unwritable(addStatus)
        }
    }

    func removeSecret(for identifier: UUID) throws {
        let status = SecItemDelete(baseQuery(for: identifier) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unwritable(status)
        }
    }

    private func baseQuery(for identifier: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier.uuidString,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}
