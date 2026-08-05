import SwiftUI

struct AddServerPage: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: PanelPage.addServer.title) {
                router.goBack()
            }
            PagePlaceholder(symbol: "plus.rectangle.on.folder", message: "The form comes next")
        }
    }
}
