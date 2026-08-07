import Foundation
import Testing

@testable import ProxmoxBar

@MainActor
private final class StubUpdater: SoftwareUpdater {
    var canCheckForUpdates: Bool
    var checksAutomatically: Bool
    private(set) var checks = 0

    init(canCheck: Bool = true, automatic: Bool = true) {
        canCheckForUpdates = canCheck
        checksAutomatically = automatic
    }

    func checkForUpdates() {
        checks += 1
    }
}

@Suite("App updates")
@MainActor
struct AppUpdatesTests {
    @Test("Without an updater the section has nothing to offer")
    func unsupportedWithoutUpdater() {
        let updates = AppUpdates(updater: nil)
        #expect(updates.isSupported == false)
        #expect(updates.canCheck == false)
        #expect(updates.checksAutomatically == false)
    }

    @Test("Asking for a check reaches the updater")
    func checkReachesTheUpdater() {
        let stub = StubUpdater()
        let updates = AppUpdates(updater: stub)
        updates.checkNow()
        #expect(stub.checks == 1)
    }

    @Test("The automatic switch is written through to the updater")
    func automaticSwitchIsWrittenThrough() {
        let stub = StubUpdater(automatic: true)
        let updates = AppUpdates(updater: stub)
        #expect(updates.checksAutomatically)

        updates.checksAutomatically = false
        #expect(stub.checksAutomatically == false)
    }

    @Test("Readiness is read back from the updater, never assumed")
    func readinessComesFromTheUpdater() {
        let stub = StubUpdater(canCheck: false)
        let updates = AppUpdates(updater: stub)
        #expect(updates.canCheck == false)

        stub.canCheckForUpdates = true
        updates.refresh()
        #expect(updates.canCheck)
    }

    #if DEBUG
        @Test("A development build ships no updater at all")
        func developmentBuildHasNoUpdater() {
            #expect(AppUpdates().isSupported == false)
        }
    #endif
}
