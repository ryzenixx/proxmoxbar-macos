import SwiftUI

struct DashboardFailure: View {
    let message: String
    let retry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.red)

            Text("Can't read the cluster")
                .font(.callout.weight(.medium))
                .padding(.top, 10)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            Button(action: run) {
                Group {
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Try Again")
                    }
                }
                .frame(width: 76)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isRetrying)
            .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func run() {
        isRetrying = true
        Task {
            await retry()
            isRetrying = false
        }
    }
}
