import SwiftUI

struct ServerFormContent<Success: View>: View {
    let model: ServerFormModel
    let submitTitle: String
    @ViewBuilder let success: () -> Success

    var body: some View {
        switch model.phase {
        case .awaitingTrust(let approvalID, let certificate, let problems):
            CertificateApprovalView(
                certificate: certificate,
                problems: problems,
                onTrust: { model.trustPresentedCertificate(approvalID) },
                onCancel: { model.cancelSubmission() }
            )
        case .saved:
            success()
        case .editing, .checking, .failed:
            ServerFormFields(model: model, submitTitle: submitTitle)
        }
    }
}
