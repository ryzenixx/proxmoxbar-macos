import AppKit

@MainActor
final class PollingSchedule {
    private static let interval: Duration = .seconds(5)

    private var periodicTask: Task<Void, Never>?
    private var wakeTask: Task<Void, Never>?

    deinit {
        periodicTask?.cancel()
        wakeTask?.cancel()
    }

    func start(_ poll: @escaping @MainActor () async -> Void) {
        guard periodicTask == nil else { return }

        periodicTask = Task {
            while !Task.isCancelled {
                await poll()
                try? await Task.sleep(for: Self.interval)
            }
        }
        wakeTask = Task {
            let wakes = NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.didWakeNotification
            )
            for await _ in wakes {
                await poll()
            }
        }
    }

    func stop() {
        periodicTask?.cancel()
        periodicTask = nil
        wakeTask?.cancel()
        wakeTask = nil
    }
}
