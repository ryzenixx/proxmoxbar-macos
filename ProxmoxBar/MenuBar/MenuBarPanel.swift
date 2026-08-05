import SwiftUI

struct MenuBarPanel: View {
    private static let width: CGFloat = 360
    private static let height: CGFloat = 400

    @State private var router = PanelRouter()
    @State private var store = ServerStore()

    var body: some View {
        page
            .frame(width: Self.width, height: Self.height, alignment: .top)
            .environment(router)
            .environment(store)
    }

    @ViewBuilder
    private var page: some View {
        switch router.page {
        case .dashboard: DashboardPage()
        case .addServer: AddServerPage()
        case .settings: SettingsPage()
        }
    }
}
