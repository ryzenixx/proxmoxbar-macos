import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let welcome = WelcomePresenter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        welcome.presentIfNeeded()
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
