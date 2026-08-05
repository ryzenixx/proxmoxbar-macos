import SwiftUI

@main
struct ProxmoxBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
