import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ServerStore()
    let menuBar = MenuBarPreference()
    let guestList = GuestListPreferences()
    let notifications = AppNotifications()
    let updates = AppUpdates()
    private(set) lazy var dashboard = DashboardModel(store: store, notifier: notifications)

    private let welcome = WelcomePresenter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notifications.configure()
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
