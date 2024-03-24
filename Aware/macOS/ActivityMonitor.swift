//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import OSLog

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityMonitor")

/// Automatically tracks macOS user input activity.
/// Timer continues running as long as user has made an input within the `userIdleSeconds` interval.
/// Sleeping or waking the computer will reset the timer back to zero.
@MainActor
class ActivityMonitor {
    /// The duration since the last user event to consider time idle.
    let userIdle: Duration

    /// The duration of idle timer tolerance
    let userIdleTolerance: Duration = .seconds(5)

    var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.log(
                "State changed from \(oldValue, privacy: .public) to \(newValue, privacy: .public)")
            updatesChannel.send(newValue)
        }
    }

    typealias Updates = WatchChannel<TimerState<UTCClock>>.Subscription
    private var updatesChannel = WatchChannel<TimerState<UTCClock>>()

    var stateUpdates: Updates {
        updatesChannel.subscribe()
    }

    private var updateTask: Task<Void, Never>?

    init(userIdleSeconds: TimeInterval) {
        userIdle = Duration(timeInterval: userIdleSeconds)

        updateTask = Task { @MainActor [weak self] in
            do {
                logger.debug("Starting ActivityMonitor update task")

                async let updateTask: () = { @MainActor in
                    while true {
                        guard let self else { break }
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
                            try await waitUntilNextUserActivityEvent()
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

                async let notificationsTask: () = { @MainActor in
                    for await name in NSWorkspace.shared.notificationCenter.mergeNotifications(
                        named: sleepWakeNotifications
                    ).map({ notification in notification.name }) {
                        logger.log("Received \(name.rawValue, privacy: .public)")
                        guard let self else { break }

                        switch name {
                        case NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                             NSWorkspace.willPowerOffNotification:
                            self.state.deactivate()
                        case NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification:
                            self.state.activate()
                        default:
                            assertionFailure("unexpected notification name: \(name)")
                        }
                    }
                }()

                try await updateTask
                await notificationsTask
                try Task.checkCancellation()

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
}

private let sleepWakeNotifications = [
    NSWorkspace.willSleepNotification,
    NSWorkspace.didWakeNotification,
    NSWorkspace.screensDidSleepNotification,
    NSWorkspace.screensDidWakeNotification,
    NSWorkspace.willPowerOffNotification,
]

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

func waitUntilNextUserActivityEvent() async throws {
    for await _ in NSEvent.globalEvents(matching: userActivityEventMask) {
        return
    }
}

private func secondsSinceLastUserEvent() -> Duration {
    userActivityEventTypes.map { eventType in
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: eventType)
    }.min().map { ti in Duration(timeInterval: ti) } ?? .zero
}

#endif
