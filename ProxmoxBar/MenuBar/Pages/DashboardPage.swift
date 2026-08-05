import SwiftUI

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        NoServersView {
            router.go(to: .addServer)
        }
    }
}
