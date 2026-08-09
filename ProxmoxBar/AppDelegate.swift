import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ServerStore()
    let menuBar = MenuBarPreference()
    let guestList = GuestListPreferences()
    let updates = AppUpdates()
    private(set) lazy var dashboard = DashboardModel(store: store)

    private let welcome = WelcomePresenter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        welcome.presentIfNeeded()
        dashboard.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dashboard.stopMonitoring()
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
