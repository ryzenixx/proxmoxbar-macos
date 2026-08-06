import Foundation
import Testing

@testable import ProxmoxBar

@MainActor
private final class StubLoginItem: LoginItemController {
    var status: LaunchAtLogin.Status
    var registerError: (any Error)?
    var unregisterError: (any Error)?
    private(set) var openedSystemSettings = false

    init(status: LaunchAtLogin.Status = .disabled) {
        self.status = status
    }

    func register() throws {
        if let registerError { throw registerError }
        status = .enabled
    }

    func unregister() throws {
        if let unregisterError { throw unregisterError }
        status = .disabled
    }

    func openSystemSettings() {
        openedSystemSettings = true
    }
}

private struct Denied: LocalizedError {
    var errorDescription: String? { "Operation not permitted." }
}

@Suite("Launch at login")
@MainActor
struct LaunchAtLoginTests {
    @Test("The state comes from the system, not from a stored preference")
    func readsStateFromTheSystem() {
        let item = StubLoginItem(status: .enabled)
        let launch = LaunchAtLogin(controller: item)
        #expect(launch.isOn)

        item.status = .disabled
        launch.refresh()
        #expect(launch.isOn == false)
    }

    @Test("Turning it on registers the app")
    func turningOnRegisters() {
        let launch = LaunchAtLogin(controller: StubLoginItem())
        launch.setEnabled(true)
        #expect(launch.status == .enabled)
        #expect(launch.failure == nil)
    }

    @Test("Turning it off unregisters the app")
    func turningOffUnregisters() {
        let launch = LaunchAtLogin(controller: StubLoginItem(status: .enabled))
        launch.setEnabled(false)
        #expect(launch.status == .disabled)
    }

    @Test("Awaiting approval still counts as on and offers a way to System Settings")
    func approvalCountsAsOn() {
        let item = StubLoginItem(status: .requiresApproval)
        let launch = LaunchAtLogin(controller: item)

        #expect(launch.isOn)
        #expect(launch.isNoteAProblem == false)
        #expect(launch.note != nil)

        launch.openSystemSettings()
        #expect(item.openedSystemSettings)
    }

    @Test("A refused registration is reported and leaves the switch off")
    func refusedRegistrationIsReported() {
        let item = StubLoginItem()
        item.registerError = Denied()
        let launch = LaunchAtLogin(controller: item)

        launch.setEnabled(true)

        #expect(launch.failure == "Operation not permitted.")
        #expect(launch.isOn == false)
        #expect(launch.isNoteAProblem)
    }

    @Test("An unknown state says nothing and still lets the switch be tried")
    func unknownStateStaysSilent() {
        let launch = LaunchAtLogin(controller: StubLoginItem(status: .unknown))
        #expect(launch.isOn == false)
        #expect(launch.note == nil)
        #expect(launch.isNoteAProblem == false)
    }

    @Test("A registration refused from an unknown state reports what the system said")
    func unknownStateStillReportsRealErrors() {
        let item = StubLoginItem(status: .unknown)
        item.registerError = Denied()
        let launch = LaunchAtLogin(controller: item)

        launch.setEnabled(true)

        #expect(launch.note == "Operation not permitted.")
        #expect(launch.isNoteAProblem)
    }

    @Test("A new attempt clears the previous failure")
    func retryClearsTheFailure() {
        let item = StubLoginItem()
        item.registerError = Denied()
        let launch = LaunchAtLogin(controller: item)
        launch.setEnabled(true)
        #expect(launch.failure != nil)

        item.registerError = nil
        launch.setEnabled(true)
        #expect(launch.failure == nil)
        #expect(launch.status == .enabled)
    }
}
