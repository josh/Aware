//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import OSLog

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "ActivityMonitor"
)

struct ActivityMonitor {
    /// Initial timer state
    let initialState: TimerState<UTCClock>

    /// The duration since the last user event to consider time idle.
    let userIdle: Duration

    /// The duration of idle timer tolerance
    let userIdleTolerance: Duration = .seconds(5)

    /// Subscribe to an async stream of the latest `TimerState` events.
    /// - Returns: An async sequence of `TimerState` values.
    func updates() -> AsyncStream<TimerState<UTCClock>> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { @MainActor yield in
            do {
                logger.info("Starting ActivityMonitor update task: \(initialState, privacy: .public)")

                var state = initialState {
                    didSet {
                        let newValue = state
                        if oldValue != newValue {
                            logger.log(
                                "State changed from \(oldValue, privacy: .public) to \(newValue, privacy: .public)")
                            yield(newValue)
                        } else {
                            logger.debug("No state change \(newValue, privacy: .public)")
                        }
                    }
                }

                async let notificationsTask: () = { @MainActor in
                    for await name in NSWorkspace.shared.notificationCenter.mergeNotifications(
                        named: sleepWakeNotifications
                    ).map(\.name) {
                        logger.log("Received \(name.rawValue, privacy: .public)")

                        switch name {
                        case NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                             NSWorkspace.willPowerOffNotification:
                            state.deactivate()
                        case NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification:
                            state.activate()
                        default:
                            assertionFailure("unexpected notification: \(name.rawValue)")
                        }
                    }
                }()

                while !Task.isCancelled {
                    let lastUserEvent = secondsSinceLastUserEvent()
                    let idleRemaining = userIdle - lastUserEvent
                    logger.debug("Last user event \(lastUserEvent, privacy: .public) ago")

                    if idleRemaining <= .zero {
                        state.deactivate()

                        logger.debug("Waiting for user activity event")
                        let now: ContinuousClock.Instant = .now
                        try await waitUntilNextUserActivityEvent()
                        logger.debug("Received user activity event after \(.now - now, privacy: .public)")
                    } else {
                        state.activate()

                        logger.debug("Sleeping for \(idleRemaining, privacy: .public)")
                        let now: ContinuousClock.Instant = .now
                        try await Task.sleep(for: idleRemaining, tolerance: userIdleTolerance)
                        logger.debug("Slept for \(.now - now, privacy: .public)")
                    }
                }

                await notificationsTask

                assert(Task.isCancelled)
                try Task.checkCancellation()

                logger.info("Finished ActivityMonitor update task")
            } catch is CancellationError {
                logger.info("ActivityMonitor update task canceled")
            } catch {
                logger.error("ActivityMonitor update task canceled unexpectedly: \(error, privacy: .public)")
            }
        }
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
