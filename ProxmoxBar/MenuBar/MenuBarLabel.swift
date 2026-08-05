import SwiftUI

struct MenuBarLabel: View {
    private static let side: CGFloat = 14

    var body: some View {
        Image(.menuBarIcon)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: Self.side, height: Self.side)
    }
}
