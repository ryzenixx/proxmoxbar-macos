import SwiftUI

struct SettingsPage: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "gearshape")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Nothing to configure yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
