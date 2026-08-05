import Foundation
import Testing

@testable import ProxmoxBar

@Suite("Bundle configuration")
struct BundleConfigurationTests {
    @Test("The bundle identifier is the one installed copies expect")
    func bundleIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "com.proxmoxbar.app")
    }

    @Test("The app stays out of the dock and the app switcher")
    func runsAsAnAgent() {
        let value = Bundle.main.object(forInfoDictionaryKey: "LSUIElement")
        #expect(value as? Bool == true)
    }

    @Test("The update feed still points at the published appcast")
    func updateFeedURL() throws {
        let expected = """
            https://raw.githubusercontent.com/ryzenixx/proxmoxbar-macos/main/appcast.xml
            """
        let value = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL")
        let feed = try #require(value as? String)
        #expect(feed == expected)
    }
}
