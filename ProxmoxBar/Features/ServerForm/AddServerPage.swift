import SwiftUI

struct AddServerPage: View {
    @Environment(PanelRouter.self) private var router

    let makeServerForm: @MainActor (ServerFormModel.Mode) -> ServerFormModel

    @State private var model: ServerFormModel?

    private var title: String {
        switch model?.phase {
        case .awaitingTrust: "Check the Certificate"
        case .saved: "Server Added"
        default: PanelPage.addServer.title
        }
    }

    private func back() {
        let phase = model?.phase
        model?.cancelSubmission()
        if case .awaitingTrust = phase { return }
        router.goBack()
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: title) {
                back()
            }
            if let model {
                ServerFormContent(model: model, submitTitle: "Connect") {
                    ServerConnectedView(
                        name: model.savedName,
                        version: model.version,
                        summary: model.summary,
                        onDone: { router.reset() }
                    )
                }
            }
        }
        .task {
            guard model == nil else { return }
            model = makeServerForm(.adding)
        }
        .onDisappear { model?.cancelSubmission() }
    }
}
