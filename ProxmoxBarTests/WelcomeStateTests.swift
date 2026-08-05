import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Welcome state")
@MainActor
struct WelcomeStateTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "ProxmoxBarTests.\(UUID().uuidString)"))
    }

    @Test("A fresh install has not seen the welcome window")
    func startsUnseen() throws {
        let state = WelcomeState(defaults: try makeDefaults())
        #expect(state.hasBeenSeen == false)
    }

    @Test("Being seen once survives a relaunch")
    func seenSurvivesRelaunch() throws {
        let defaults = try makeDefaults()
        WelcomeState(defaults: defaults).markSeen()
        #expect(WelcomeState(defaults: defaults).hasBeenSeen)
    }

    @Test("Marking it seen twice changes nothing")
    func markingTwiceIsIdempotent() throws {
        let state = WelcomeState(defaults: try makeDefaults())
        state.markSeen()
        state.markSeen()
        #expect(state.hasBeenSeen)
    }

    @Test("Forgetting brings the welcome window back")
    func forgetRestoresIt() throws {
        let defaults = try makeDefaults()
        let state = WelcomeState(defaults: defaults)
        state.markSeen()
        state.forget()
        #expect(state.hasBeenSeen == false)
        #expect(WelcomeState(defaults: defaults).hasBeenSeen == false)
    }
}
