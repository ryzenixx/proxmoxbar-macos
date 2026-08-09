import Foundation
import Observation

@MainActor
@Observable
final class AppUpdates {
    private(set) var canCheck = false

    var checksAutomatically: Bool {
        didSet {
            guard checksAutomatically != oldValue else { return }
            updater?.checksAutomatically = checksAutomatically
        }
    }

    @ObservationIgnored private let updater: (any SoftwareUpdater)?

    init(updater: (any SoftwareUpdater)? = AppUpdates.bundledUpdater()) {
        self.updater = updater
        canCheck = updater?.canCheckForUpdates ?? false
        checksAutomatically = updater?.checksAutomatically ?? false
    }

    var isSupported: Bool {
        updater != nil
    }

    func refresh() {
        canCheck = updater?.canCheckForUpdates ?? false
    }

    func checkNow() {
        updater?.checkForUpdates()
        refresh()
    }

    private static func bundledUpdater() -> (any SoftwareUpdater)? {
        #if canImport(Sparkle) && !DEBUG
            return SparkleUpdater()
        #else
            return nil
        #endif
    }
}
