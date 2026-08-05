import SwiftUI

struct MenuBarPanel: View {
    private static let width: CGFloat = 360
    private static let minimumContentHeight: CGFloat = 320

    @State private var router = PanelRouter()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelHeader()
            Divider()
            page
                .frame(maxWidth: .infinity, minHeight: Self.minimumContentHeight, alignment: .top)
            Divider()
            PanelFooter()
        }
        .frame(width: Self.width)
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

private struct PanelHeader: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        HStack(spacing: 8) {
            if router.canGoBack {
                Button {
                    router.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .buttonStyle(.plain)
            }
            Text(router.page.title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct PanelFooter: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        HStack {
            Button {
                router.go(to: .settings)
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
