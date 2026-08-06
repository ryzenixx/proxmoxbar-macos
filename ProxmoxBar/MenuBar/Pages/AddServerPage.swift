import SwiftUI

struct AddServerPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store

    @State private var model: ServerFormModel?

    private var title: String {
        switch model?.phase {
        case .awaitingTrust: "Check the Certificate"
        case .saved: "Server Added"
        default: PanelPage.addServer.title
        }
    }

    private func back() {
        if case .awaitingTrust = model?.phase {
            model?.cancelTrust()
            return
        }
        router.goBack()
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: title) {
                back()
            }
            if let model {
                step(for: model)
            }
        }
        .task {
            guard model == nil else { return }
            model = ServerFormModel(api: ProxmoxAPIClient(), store: store)
        }
    }

    @ViewBuilder
    private func step(for model: ServerFormModel) -> some View {
        if case .awaitingTrust(let certificate, let problems) = model.phase {
            CertificateApprovalView(
                certificate: certificate,
                problems: problems,
                onTrust: { Task { await model.trustPresentedCertificate() } },
                onCancel: { model.cancelTrust() }
            )
        } else if model.phase == .saved {
            ServerConnectedView(
                name: model.savedName,
                version: model.version,
                summary: model.summary,
                onDone: { router.reset() }
            )
        } else {
            ServerFormFields(model: model, submitTitle: "Connect")
        }
    }
}
