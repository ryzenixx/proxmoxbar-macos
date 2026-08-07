import Foundation

@MainActor
protocol SoftwareUpdater: AnyObject {
    var canCheckForUpdates: Bool { get }
    var checksAutomatically: Bool { get set }
    func checkForUpdates()
}

#if canImport(Sparkle)
    import Sparkle

    @MainActor
    final class SparkleUpdater: SoftwareUpdater {
        private let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        var canCheckForUpdates: Bool {
            controller.updater.canCheckForUpdates
        }

        var checksAutomatically: Bool {
            get { controller.updater.automaticallyChecksForUpdates }
            set { controller.updater.automaticallyChecksForUpdates = newValue }
        }

        func checkForUpdates() {
            controller.updater.checkForUpdates()
        }
    }
#endif
