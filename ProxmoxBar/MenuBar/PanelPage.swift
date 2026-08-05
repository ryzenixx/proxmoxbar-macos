import Foundation

enum PanelPage: Hashable, CaseIterable {
    case dashboard
    case settings

    var title: String {
        switch self {
        case .dashboard: "ProxmoxBar"
        case .settings: "Settings"
        }
    }
}
