import Foundation
import Observation

@MainActor
@Observable
final class GuestListPreferences {
    static let sortKey = "ProxmoxBar.guestSort"

    var sort: GuestSort {
        didSet {
            guard sort != oldValue else { return }
            defaults.set(sort.rawValue, forKey: Self.sortKey)
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.sortKey)
        sort = stored.flatMap(GuestSort.init(rawValue:)) ?? .identifier
    }
}
