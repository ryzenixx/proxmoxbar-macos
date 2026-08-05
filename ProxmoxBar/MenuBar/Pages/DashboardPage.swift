import SwiftUI

struct DashboardPage: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "server.rack")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No server configured")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
