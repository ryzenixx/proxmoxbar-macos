import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ProxmoxViewModel
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController

    enum Screen {
        case dashboard
        case settings
    }

    enum Tab {
        case resources
        case storage
    }

    @State private var currentScreen: Screen = .dashboard
    @State private var selectedTab: Tab = .resources
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            if currentScreen == .dashboard {
                MenuBarDashboardView(
                    viewModel: viewModel,
                    settings: settings,
                    selectedTab: $selectedTab,
                    currentScreen: $currentScreen,
                    isRefreshing: $isRefreshing
                )
                .transition(.move(edge: .leading))
            } else {
                SettingsView(
                    settings: settings,
                    launchService: launchService,
                    updaterController: updaterController
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentScreen = .dashboard
                    }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentScreen)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
        .background(WindowAccessor { window in
            guard let window else { return }
            if window.styleMask.contains(.resizable) {
                window.styleMask.remove(.resizable)
            }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isOpaque = false
        })
        .background(CursorFixView())
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .task {
            while !Task.isCancelled {
                await viewModel.loadData()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
}
