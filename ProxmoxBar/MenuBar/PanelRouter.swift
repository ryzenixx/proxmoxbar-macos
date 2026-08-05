import Observation

@MainActor
@Observable
final class PanelRouter {
    private(set) var page: PanelPage
    private var history: [PanelPage] = []

    init(page: PanelPage = .dashboard) {
        self.page = page
    }

    var canGoBack: Bool {
        !history.isEmpty
    }

    func go(to destination: PanelPage) {
        guard destination != page else { return }
        history.append(page)
        page = destination
    }

    func goBack() {
        guard let previous = history.popLast() else { return }
        page = previous
    }

    func reset() {
        history.removeAll()
        page = .dashboard
    }
}
