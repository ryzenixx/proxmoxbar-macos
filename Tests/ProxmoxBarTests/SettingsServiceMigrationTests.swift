import XCTest
@testable import ProxmoxBar

final class SettingsServiceMigrationTests: XCTestCase {
    private func makeIsolatedStorage() -> (suiteName: String, defaults: UserDefaults, backupURL: URL) {
        let suiteName = "ProxmoxBarTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create isolated UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)

        let backupDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ProxmoxBarTests-\(UUID().uuidString)", isDirectory: true)
        let backupURL = backupDirectory.appendingPathComponent("proxmox_servers.json")

        return (suiteName, defaults, backupURL)
    }

    private func cleanupStorage(_ defaults: UserDefaults, suiteName: String, backupURL: URL) {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: backupURL.deletingLastPathComponent())
    }

    func testDecodesServerWithoutLegacyID() throws {
        let (suiteName, defaults, backupURL) = makeIsolatedStorage()
        defer { cleanupStorage(defaults, suiteName: suiteName, backupURL: backupURL) }

        let payload = """
        [
          {
            "name": "Home",
            "url": "https://pve.local:8006",
            "tokenId": "proxmoxbar@pve!monitor",
            "secret": "abc123"
          }
        ]
        """
        defaults.set(Data(payload.utf8), forKey: "proxmox_servers")

        let service = SettingsService(defaults: defaults, backupFileURL: backupURL)

        XCTAssertEqual(service.servers.count, 1)
        XCTAssertEqual(service.servers[0].name, "Home")
        XCTAssertNotEqual(service.servers[0].id.uuidString, "")
    }

    func testMigratesLegacyServersKeyToPrimaryKey() throws {
        let (suiteName, defaults, backupURL) = makeIsolatedStorage()
        defer { cleanupStorage(defaults, suiteName: suiteName, backupURL: backupURL) }

        let payload = """
        [
          {
            "name": "Lab",
            "url": "https://lab.local:8006",
            "token_id": "root@pam!cli",
            "token_secret": "xyz456"
          }
        ]
        """
        defaults.set(Data(payload.utf8), forKey: "proxmoxServers")

        let service = SettingsService(defaults: defaults, backupFileURL: backupURL)

        XCTAssertEqual(service.servers.count, 1)
        XCTAssertEqual(service.servers[0].tokenId, "root@pam!cli")
        XCTAssertEqual(service.servers[0].secret, "xyz456")
        XCTAssertNotNil(defaults.data(forKey: "proxmox_servers"))
    }

    func testRecoversFromBackupWhenPrimaryPayloadIsCorrupt() throws {
        let (suiteName, defaults, backupURL) = makeIsolatedStorage()
        defer { cleanupStorage(defaults, suiteName: suiteName, backupURL: backupURL) }

        let backupPayload = """
        [
          {
            "id": "31D8D5D9-A695-4B98-8BC2-68A6F1C9F2CB",
            "name": "Recovery",
            "url": "https://backup.local:8006",
            "tokenId": "ops@pve!backup",
            "secret": "safe"
          }
        ]
        """

        let backupData = Data(backupPayload.utf8)
        defaults.set(Data("not-json".utf8), forKey: "proxmox_servers")
        defaults.set(backupData, forKey: "proxmox_servers_backup")

        let service = SettingsService(defaults: defaults, backupFileURL: backupURL)

        XCTAssertEqual(service.servers.count, 1)
        XCTAssertEqual(service.servers[0].name, "Recovery")
        XCTAssertNotNil(defaults.data(forKey: "proxmox_servers_corrupt"))
        XCTAssertEqual(defaults.data(forKey: "proxmox_servers_backup"), backupData)
    }

    func testRecoversFromDiskBackupWhenDefaultsAreEmpty() throws {
        let (suiteName, defaults, backupURL) = makeIsolatedStorage()
        defer { cleanupStorage(defaults, suiteName: suiteName, backupURL: backupURL) }

        let payload = """
        [
          {
            "id": "FEFA7086-4F68-440C-956D-168E56365EE7",
            "name": "DiskBackup",
            "url": "https://disk.local:8006",
            "tokenId": "ops@pve!disk",
            "secret": "restore"
          }
        ]
        """
        try FileManager.default.createDirectory(
            at: backupURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(payload.utf8).write(to: backupURL, options: .atomic)

        let service = SettingsService(defaults: defaults, backupFileURL: backupURL)

        XCTAssertEqual(service.servers.count, 1)
        XCTAssertEqual(service.servers[0].name, "DiskBackup")
        XCTAssertNotNil(defaults.data(forKey: "proxmox_servers"))
    }
}
