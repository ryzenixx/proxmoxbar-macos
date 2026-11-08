@MainActor
final class AppServices {
    let store: ServerStore
    let menuBar = MenuBarPreference()
    let guestList = GuestListPreferences()
    let notifications: AppNotifications
    let updates = AppUpdates()
    let watcher: ServerWatcher
    let dashboard: DashboardModel

    init() {
        let store = ServerStore()
        let notifications = AppNotifications()
        let watcher = ServerWatcher(
            store: store, api: ProxmoxAPIClient(), notifier: notifications
        )

        self.store = store
        self.notifications = notifications
        self.watcher = watcher
        dashboard = DashboardModel(store: store, api: ProxmoxAPIClient(), recorder: watcher)
    }

    func makeServerForm(mode: ServerFormModel.Mode) -> ServerFormModel {
        ServerFormModel(mode: mode, api: ProxmoxAPIClient(), store: store)
    }
}
