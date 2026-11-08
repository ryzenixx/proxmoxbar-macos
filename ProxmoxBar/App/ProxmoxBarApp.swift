import SwiftUI

@main
struct ProxmoxBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        let services = appDelegate.services

        MenuBarExtra {
            MenuBarPanel(makeServerForm: services.makeServerForm)
                .environment(services.store)
                .environment(services.dashboard)
                .environment(services.menuBar)
                .environment(services.guestList)
                .environment(services.notifications)
                .environment(services.updates)
        } label: {
            MenuBarLabel(dashboard: services.dashboard, preference: services.menuBar)
        }
        .menuBarExtraStyle(.window)
    }
}
