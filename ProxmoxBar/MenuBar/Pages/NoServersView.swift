import SwiftUI

struct NoServersView: View {
    let onAddServer: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            Image(.menuBarIcon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 34)
                .foregroundStyle(.tint)

            Text("Keep an eye on your cluster")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.top, 14)

            Text("Add a server and it stays one click away, up here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            capabilities
                .padding(.top, 26)

            Spacer(minLength: 12)

            Button(action: onAddServer) {
                Text("Add Your First Server")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HelpLinks()
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var capabilities: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capability(symbol: "chart.bar.fill", text: "Nodes, machines and storage at a glance")
            Divider().padding(.leading, 30)
            Capability(symbol: "power", text: "Start, stop and restart without a browser")
            Divider().padding(.leading, 30)
            Capability(symbol: "lock.fill", text: "Your token never leaves the keychain")
        }
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
    }
}

private struct Capability: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(.tint)
                .frame(width: 18)
            Text(text)
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}

private struct HelpLinks: View {
    var body: some View {
        HStack(spacing: 6) {
            if let guide = WelcomeLinks.tokenGuide {
                HelpLink("How to create a token", destination: guide)
            }
            Text("·")
                .foregroundStyle(.secondary)
            if let issues = WelcomeLinks.issues {
                HelpLink("Report a problem", destination: issues)
            }
        }
        .font(.footnote.weight(.medium))
    }
}

private struct HelpLink: View {
    let title: String
    let destination: URL

    init(_ title: String, destination: URL) {
        self.title = title
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            Text(title)
                .underline()
                .foregroundStyle(.primary)
        }
    }
}
