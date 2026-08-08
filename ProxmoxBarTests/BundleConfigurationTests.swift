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

    @Test("The build number is a plain counter, never a version string")
    func buildNumberIsACounter() throws {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let build = try #require(value as? String)
        #expect(Int(build) != nil)
    }

    @Test("The build number outranks every build already installed from 2.x")
    func buildNumberOutranksTheInstalledBase() throws {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let build = try #require(value as? String)
        let counter = try #require(Int(build))
        #expect(counter > 2)
    }

    @Test("The public version is three numbers separated by dots")
    func publicVersionIsSemantic() throws {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let version = try #require(value as? String)
        let parts = version.split(separator: ".")
        #expect(parts.count == 3)
        #expect(parts.allSatisfy { Int($0) != nil })
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

@Suite("App information")
struct AppInfoTests {
    @Test("The version and build come from the bundle, not from a literal")
    func readsVersionFromBundle() throws {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        #expect(AppInfo.version == (short as? String ?? "—"))
        #expect(AppInfo.build == (build as? String ?? "—"))
    }

    @Test("The summary pairs the version with its build")
    func summaryPairsBoth() {
        #expect(AppInfo.versionSummary == "\(AppInfo.version) (\(AppInfo.build))")
    }

    @Test("Every published link is a valid URL")
    func linksResolve() {
        #expect(AppLinks.repository != nil)
        #expect(AppLinks.issues != nil)
        #expect(AppLinks.support != nil)
        #expect(AppLinks.tokenGuide != nil)
    }
}

@Suite("Local network access")
struct LocalNetworkTests {
    @Test("The app explains why it needs the local network, as macOS 15 requires")
    func declaresLocalNetworkUsage() throws {
        let value = Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription")
        let reason = try #require(value as? String)
        #expect(reason.isEmpty == false)
    }
}
