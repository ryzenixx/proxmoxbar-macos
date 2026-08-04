import Foundation

struct AppConfig {
    static let appName = "Proxmox Bar"

    static var appVersion: String {
        if let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !bundleVersion.isEmpty {
            return bundleVersion
        }
        return "0.0.0"
    }
}
