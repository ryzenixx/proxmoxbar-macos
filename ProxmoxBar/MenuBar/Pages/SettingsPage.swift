import SwiftUI

struct SettingsPage: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    router.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .buttonStyle(.plain)
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            PagePlaceholder(symbol: "gearshape", message: "Nothing to configure yet")
        }
    }
}
