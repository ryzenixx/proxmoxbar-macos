import Foundation
import Observation

@MainActor
@Observable
final class MenuBarPreference {
    enum Content: String, CaseIterable, Hashable, Sendable {
        case icon
        case running
        case processor

        var label: String {
            switch self {
            case .icon: "Icon only"
            case .running: "Running machines"
            case .processor: "CPU usage"
            }
        }
    }

    static let storageKey = "ProxmoxBar.menuBarContent"

    var content: Content {
        didSet {
            guard content != oldValue else { return }
            defaults.set(content.rawValue, forKey: Self.storageKey)
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.storageKey)
        content = stored.flatMap(Content.init(rawValue:)) ?? .icon
    }
}
