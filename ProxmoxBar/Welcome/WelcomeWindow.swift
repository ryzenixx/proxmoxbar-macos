import SwiftUI

struct WelcomeWindow: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            WelcomeHeader()
            WelcomeWhereToFindIt()
            Divider()
            WelcomeFooter(dismiss: onDismiss)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct WelcomeHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("ProxmoxBar")
                .font(.title2.weight(.semibold))
            Text(
                "Watch your Proxmox cluster and power your machines on and off, without leaving the menu bar."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }
}

private struct WelcomeWhereToFindIt: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.up")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text("It lives at the top of your screen")
                    .font(.callout.weight(.medium))
                Text(
                    "Click \(Image(.menuBarIcon)) in the menu bar to open ProxmoxBar. There is no window and no dock icon."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}

private struct WelcomeFooter: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let repository = WelcomeLinks.repository {
                Link("GitHub", destination: repository)
            }
            if let support = WelcomeLinks.support {
                Link("Support the work", destination: support)
            }
            Spacer()
            Button("Get Started", action: dismiss)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
