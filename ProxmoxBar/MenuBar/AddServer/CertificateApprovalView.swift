import SwiftUI

struct CertificateApprovalView: View {
    let certificate: ServerCertificate
    let problems: [TrustProblem]
    let onTrust: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Check this certificate")
                .font(.headline)

            Text("Proxmox signs its own certificates, so your Mac cannot vouch for this one.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                Field(label: "Issued to", value: certificate.subject)
                if let issuer = certificate.issuer {
                    Field(label: "Issued by", value: issuer)
                }
                if let expiry = certificate.expiry {
                    Field(
                        label: "Expires",
                        value: expiry.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                Field(label: "SHA-256", value: certificate.fingerprint, isMonospaced: true)
            }
            .padding(.top, 14)

            if problems.isEmpty == false {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(problems, id: \.self) { problem in
                        Label(problem.summary, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(problem.isExpected ? Color.secondary : Color.orange)
                    }
                }
                .padding(.top, 12)
            }

            Text(
                "Compare the fingerprint with Datacenter → Certificates in the Proxmox web interface."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)

            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                Spacer()
                Button("Trust This Server", action: onTrust)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 18)
        }
        .padding(20)
        .frame(width: 340)
    }
}

private struct Field: View {
    let label: String
    let value: String
    var isMonospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(isMonospaced ? .caption.monospaced() : .callout)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
