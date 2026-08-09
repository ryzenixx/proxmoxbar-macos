import SwiftUI

@main
struct ProxmoxBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environment(appDelegate.store)
                .environment(appDelegate.dashboard)
                .environment(appDelegate.menuBar)
                .environment(appDelegate.guestList)
                .environment(appDelegate.notifications)
                .environment(appDelegate.updates)
        } label: {
            MenuBarLabel(dashboard: appDelegate.dashboard, preference: appDelegate.menuBar)
        }
        .menuBarExtraStyle(.window)
    }
}
