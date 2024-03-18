//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import Combine
import OSLog

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityMonitor")

/// Automatically tracks macOS user input activity.
/// Timer continues running as long as user has made an input within the `userIdleSeconds` interval.
/// Sleeping or waking the computer will reset the timer back to zero.
@MainActor
class ActivityMonitor: ObservableObject {
    /// The duration since the last user event to consider time idle.
    let userIdle: Duration

    /// The duration of idle timer tolerance
    let userIdleTolerance: Duration = .seconds(5)

    @Published var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.log("State changed from \(oldValue, privacy: .public) to \(newValue, privacy: .public)")
        }
    }

    typealias Updates = AsyncPublisher<AnyPublisher<TimerState<UTCClock>, Never>>

    var stateUpdates: Updates {
        // TODO: This uses ObservableObject's publisher to create an AsyncSequence.
        // Would be nice to implement a custom `Updates` type and remove the Combine dependency.
        $state.removeDuplicates().eraseToAnyPublisher().values
    }

    private var updateTask: Task<Void, Never>?

    init(userIdleSeconds: TimeInterval) {
        userIdle = Duration(timeInterval: userIdleSeconds)

        updateTask = Task {
            do {
                logger.debug("Starting ActivityMonitor update task")
                try await update()
                logger.debug("Finished ActivityMonitor update task")
            } catch is CancellationError {
                logger.debug("ActivityMonitor update task canceled")
            } catch {
                logger.error("ActivityMonitor update task canceled unexpectedly: \(error)")
            }
        }
    }

    deinit {
        updateTask?.cancel()
    }

    private func update() async throws {
        async let updateTask: () = { @MainActor [weak self] in
            while true {
                guard let self = self else { break }
                try Task.checkCancellation()

                var logState = self.state
                logger.debug("Updating ActivityMonitor state: \(logState, privacy: .public)")

                let lastUserEvent = secondsSinceLastUserEvent()
                let idleRemaining = self.userIdle - lastUserEvent
                let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

                logger.debug("Last user event \(lastUserEvent, privacy: .public) ago")
                if isMainDisplayAsleep {
                    logger.info("Main display is asleep")
                }

                if idleRemaining <= .zero || isMainDisplayAsleep {
                    if self.state.isActive {
                        self.state.deactivate()
                    }
                    assert(self.state.isIdle)

                    logger.debug("Waiting for user activity event")
                    _ = try await NSEvent.globalEvents(matching: userActivityEventMask).isEmpty
                    logger.debug("Received user activity event")
                } else {
                    if self.state.isIdle {
                        self.state.activate()
                    }
                    assert(self.state.isActive)

                    logger.debug("Sleeping for \(idleRemaining, privacy: .public)")
                    let now: ContinuousClock.Instant = .now
                    try await Task.sleep(for: idleRemaining, tolerance: self.userIdleTolerance)
                    logger.debug("Slept for \(.now - now, privacy: .public)")
                }

                logState = self.state
                logger.debug("Finished updating ActivityMonitor state: \(logState, privacy: .public)")
            }
        }()

        async let willSleepTask: () = { @MainActor [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.willSleepNotification).maskElements {
                logger.log("Received willSleepNotification")
                guard let self = self else { break }
                self.state.deactivate()
            }
        }()

        async let didWakeTask: () = { @MainActor [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.didWakeNotification).maskElements {
                logger.log("Received didWakeNotification")
                guard let self = self else { break }
                self.state.activate()
            }
        }()

        async let screensDidSleepTask: () = { @MainActor [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.screensDidSleepNotification).maskElements {
                logger.log("Received screensDidSleepNotification")
                guard let self = self else { break }
                self.state.deactivate()
            }
        }()

        async let screensDidWakeTask: () = { @MainActor [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.screensDidWakeNotification).maskElements {
                logger.log("Received screensDidWakeNotification")
                guard let self = self else { break }
                self.state.activate()
            }
        }()

        try await updateTask
        await willSleepTask
        await didWakeTask
        await screensDidSleepTask
        await screensDidWakeTask
    }
}

private let userActivityEventMask: NSEvent.EventTypeMask = [
    .leftMouseDown,
    .rightMouseDown,
    .mouseMoved,
    .keyDown,
    .scrollWheel,
]

private let userActivityEventTypes: [CGEventType] = [
    .leftMouseDown,
    .rightMouseDown,
    .mouseMoved,
    .keyDown,
    .scrollWheel,
]

private func secondsSinceLastUserEvent() -> Duration {
    return userActivityEventTypes.map { eventType in
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: eventType)
    }.min().map { ti in Duration(timeInterval: ti) } ?? .zero
}

#endif
