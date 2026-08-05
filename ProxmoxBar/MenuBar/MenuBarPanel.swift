import SwiftUI

struct MenuBarPanel: View {
    private static let width: CGFloat = 360
    private static let height: CGFloat = 440

    @State private var router = PanelRouter()

    var body: some View {
        page
            .frame(width: Self.width, height: Self.height, alignment: .top)
            .environment(router)
    }

    @ViewBuilder
    private var page: some View {
        switch router.page {
        case .dashboard: DashboardPage()
        case .settings: SettingsPage()
        }
    }
}
