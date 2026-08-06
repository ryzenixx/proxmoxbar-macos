import SwiftUI

struct CertificateApprovalView: View {
    let certificate: ServerCertificate
    let problems: [TrustProblem]
    let onTrust: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Proxmox signs its own certificates, so your Mac cannot vouch for this one.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            details
                .padding(.top, 14)

            if problems.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(problems, id: \.self) { problem in
                        Label(problem.summary, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(problem.isExpected ? Color.secondary : Color.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .font(.caption)
                .padding(.top, 12)
            }

            Text("Compare it with Datacenter → Certificates in the Proxmox web interface.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Button("Cancel", action: onCancel)
                    .controlSize(.large)
                Button("Trust", action: onTrust)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            DetailRow(label: "Issued to", value: certificate.subject)
            if let issuer = certificate.issuer {
                Divider()
                DetailRow(label: "Issued by", value: issuer)
            }
            if let expiry = certificate.expiry {
                Divider()
                DetailRow(
                    label: "Expires",
                    value: expiry.formatted(date: .abbreviated, time: .omitted)
                )
            }
            Divider()
            DetailRow(label: "SHA-256", value: certificate.fingerprint, isMonospaced: true)
        }
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var isMonospaced = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(isMonospaced ? .caption2.monospaced() : .caption)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
