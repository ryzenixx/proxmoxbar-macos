import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ServerStore()
    let menuBar = MenuBarPreference()
    let guestList = GuestListPreferences()
    let notifications = AppNotifications()
    let updates = AppUpdates()
    private(set) lazy var watcher = ServerWatcher(
        store: store, notifier: notifications, gate: notifications
    )
    private(set) lazy var dashboard = DashboardModel(store: store, recorder: watcher)

    private let welcome = WelcomePresenter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notifications.configure()
        welcome.presentIfNeeded()
        watcher.start()
        dashboard.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stop()
        dashboard.stopMonitoring()
    }

    nonisolated func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
