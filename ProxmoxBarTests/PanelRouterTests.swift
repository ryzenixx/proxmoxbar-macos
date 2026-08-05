import Testing

@testable import ProxmoxBar

@Suite("Panel routing")
@MainActor
struct PanelRouterTests {
    @Test("It opens on the dashboard")
    func startsOnDashboard() {
        let router = PanelRouter()
        #expect(router.page == .dashboard)
        #expect(router.canGoBack == false)
    }

    @Test("Going somewhere makes going back possible")
    func navigationBuildsHistory() {
        let router = PanelRouter()
        router.go(to: .settings)
        #expect(router.page == .settings)
        #expect(router.canGoBack)
    }

    @Test("Going back returns to the previous page")
    func goBackRestoresPreviousPage() {
        let router = PanelRouter()
        router.go(to: .settings)
        router.goBack()
        #expect(router.page == .dashboard)
        #expect(router.canGoBack == false)
    }

    @Test("Going back from the first page does nothing")
    func goBackOnRootIsInert() {
        let router = PanelRouter()
        router.goBack()
        #expect(router.page == .dashboard)
    }

    @Test("Navigating to the current page does not stack history")
    func navigatingToSelfIsIgnored() {
        let router = PanelRouter()
        router.go(to: .dashboard)
        #expect(router.canGoBack == false)
    }

    @Test("Reset returns to the dashboard and clears history")
    func resetClearsEverything() {
        let router = PanelRouter()
        router.go(to: .settings)
        router.reset()
        #expect(router.page == .dashboard)
        #expect(router.canGoBack == false)
    }

    @Test("Every page has a title")
    func everyPageHasATitle() {
        for page in PanelPage.allCases {
            #expect(page.title.isEmpty == false)
        }
    }
}
