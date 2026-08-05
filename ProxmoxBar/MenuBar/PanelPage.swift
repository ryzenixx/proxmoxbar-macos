import Foundation

enum PanelPage: Hashable, CaseIterable {
    case dashboard
    case addServer
    case settings

    var title: String {
        switch self {
        case .dashboard: "ProxmoxBar"
        case .addServer: "Add a Server"
        case .settings: "Settings"
        }
    }
}
