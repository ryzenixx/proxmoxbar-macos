import AppKit
import SwiftUI

struct PanelCommands: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        HStack(spacing: 2) {
            if router.page == .dashboard {
                PanelIconButton(symbol: "gearshape", title: "Settings") {
                    router.go(to: .settings)
                }
            }

            PanelIconButton(symbol: "power", title: "Quit ProxmoxBar") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
