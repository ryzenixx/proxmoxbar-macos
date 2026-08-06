import SwiftUI

struct UsageMeter: View {
    let value: Double

    private static let warningThreshold = 0.75
    private static let dangerThreshold = 0.9
    private static let height: CGFloat = 4

    private var fill: Color {
        switch value {
        case Self.dangerThreshold...: .red
        case Self.warningThreshold...: .orange
        default: .secondary
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                if value > 0 {
                    Capsule()
                        .fill(fill)
                        .frame(width: max(proxy.size.width * value, Self.height))
                }
            }
        }
        .frame(height: Self.height)
        .accessibilityHidden(true)
    }
}
