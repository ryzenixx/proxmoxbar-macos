import SwiftUI

@main
struct ProxmoxBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environment(appDelegate.store)
                .environment(appDelegate.dashboard)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
