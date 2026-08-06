import SwiftUI

struct MenuBarLabel: View {
    let dashboard: DashboardModel
    let preference: MenuBarPreference

    private static let side: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            Image(.menuBarIcon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Self.side, height: Self.side)
            if let reading {
                Text(reading)
                    .monospacedDigit()
            }
        }
    }

    private var reading: String? {
        guard dashboard.failureMessage == nil, let state = dashboard.visibleState else {
            return nil
        }
        switch preference.content {
        case .icon:
            return nil
        case .running:
            return "\(state.runningGuests)"
        case .processor:
            guard let usage = state.cpuUsage else { return nil }
            return "\(Int((usage * 100).rounded()))%"
        }
    }
}
