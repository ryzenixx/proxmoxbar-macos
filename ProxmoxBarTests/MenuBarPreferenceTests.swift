import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Menu bar preference")
@MainActor
struct MenuBarPreferenceTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "MenuBar.\(UUID().uuidString)"))
    }

    @Test("A fresh install shows the icon on its own")
    func defaultsToIconOnly() throws {
        let preference = MenuBarPreference(defaults: try makeDefaults())
        #expect(preference.content == .icon)
    }

    @Test("A choice survives a relaunch")
    func choiceSurvivesRelaunch() throws {
        let defaults = try makeDefaults()
        MenuBarPreference(defaults: defaults).content = .processor
        #expect(MenuBarPreference(defaults: defaults).content == .processor)
    }

    @Test("A value written by a newer build falls back instead of crashing")
    func unknownValueFallsBack() throws {
        let defaults = try makeDefaults()
        defaults.set("memoryPressure", forKey: MenuBarPreference.storageKey)
        #expect(MenuBarPreference(defaults: defaults).content == .icon)
    }

    @Test("Every mode is offered and named")
    func everyModeIsNamed() {
        #expect(MenuBarPreference.Content.allCases.count == 3)
        #expect(MenuBarPreference.Content.allCases.allSatisfy { $0.label.isEmpty == false })
    }
}
