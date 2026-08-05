import SwiftUI

struct MenuBarPanel: View {
    private static let width: CGFloat = 360
    private static let minimumHeight: CGFloat = 320

    @State private var router = PanelRouter()

    var body: some View {
        page
            .frame(width: Self.width)
            .frame(minHeight: Self.minimumHeight, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
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
