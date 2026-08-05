import Foundation
import Observation

@MainActor
@Observable
final class WelcomeState {
    static let storageKey = "ProxmoxBar.hasSeenWelcome"

    private(set) var hasBeenSeen: Bool

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasBeenSeen = defaults.bool(forKey: Self.storageKey)
    }

    func markSeen() {
        guard hasBeenSeen == false else { return }
        hasBeenSeen = true
        defaults.set(true, forKey: Self.storageKey)
    }

    func forget() {
        hasBeenSeen = false
        defaults.removeObject(forKey: Self.storageKey)
    }
}
