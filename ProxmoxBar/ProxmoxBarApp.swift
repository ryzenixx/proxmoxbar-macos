import SwiftUI

@main
struct ProxmoxBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var welcome = WelcomeState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to ProxmoxBar", id: WelcomeWindow.identifier) {
            WelcomeWindow()
                .environment(welcome)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(welcome.hasBeenSeen ? .suppressed : .presented)
        .restorationBehavior(.disabled)
    }
}
