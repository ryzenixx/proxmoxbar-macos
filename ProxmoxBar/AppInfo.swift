import Foundation

enum AppInfo {
    static var name: String {
        string(for: "CFBundleName") ?? "ProxmoxBar"
    }

    static var version: String {
        string(for: "CFBundleShortVersionString") ?? "—"
    }

    static var build: String {
        string(for: "CFBundleVersion") ?? "—"
    }

    static var versionSummary: String {
        "\(version) (\(build))"
    }

    private static func string(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            value.isEmpty == false
        else { return nil }
        return value
    }
}
