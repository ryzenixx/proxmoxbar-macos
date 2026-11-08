import SwiftUI

struct ServerFormContent<Success: View>: View {
    let model: ServerFormModel
    let submitTitle: String
    @ViewBuilder let success: () -> Success

    var body: some View {
        switch model.phase {
        case .awaitingTrust(let certificate, let problems):
            CertificateApprovalView(
                certificate: certificate,
                problems: problems,
                onTrust: { Task { await model.trustPresentedCertificate() } },
                onCancel: { model.cancelTrust() }
            )
        case .saved:
            success()
        case .editing, .checking, .failed:
            ServerFormFields(model: model, submitTitle: submitTitle)
        }
    }
}
