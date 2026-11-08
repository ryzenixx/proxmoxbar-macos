import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let services = AppServices()

    private let welcome = WelcomePresenter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        services.notifications.configure()
        welcome.presentIfNeeded()
        services.watcher.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        services.watcher.stop()
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
