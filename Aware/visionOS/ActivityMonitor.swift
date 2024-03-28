//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/23/24.
//

#if os(visionOS)

import OSLog
import UIKit

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "ActivityMonitor"
)

let fetchActivityMonitorTask: BackgroundTask = .appRefresh("fetchActivityMonitor")
let processingActivityMonitorTask: BackgroundTask = .processing("processingActivityMonitor")

struct ActivityMonitor {
    /// Initial timer state
    let initialState: TimerState<UTCClock>

    /// The minimum number of seconds to schedule between background tasks.
    let backgroundTaskInterval: Duration = .minutes(5)

    /// The duration the app can be in the background and be considered active if it's opened again.
    let backgroundGracePeriod: Duration = .hours(2)

    /// The duration after locking the device it can be considered active if it's unlocked again.
    let lockGracePeriod: Duration = .minutes(1)

    /// The max duration to allow the suspending clock to drift from the continuous clock.
    let maxSuspendingClockDrift: Duration = .seconds(10)

    /// Subscribe to an async stream of the latest `TimerState` events.
    /// - Returns: An async sequence of `TimerState` values.
    func updates() -> AsyncStream<TimerState<UTCClock>> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { @MainActor yield in
            do {
                logger.info("Starting ActivityMonitor update task: \(initialState)")

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

                let app = UIApplication.shared

                // Set initial state
                assert(app.applicationState != .background)
                assert(app.isProtectedDataAvailable)
                state.activate()

                let center = NotificationCenter.default

                async let driftTask: () = { @MainActor in
                    while !Task.isCancelled {
                        try await SuspendingClock().monitorDrift(threshold: maxSuspendingClockDrift)
                        state.deactivate()
                    }
                }()

                let notificationNames = [
                    UIApplication.didEnterBackgroundNotification,
                    UIApplication.willEnterForegroundNotification,
                    UIApplication.protectedDataDidBecomeAvailableNotification,
                    UIApplication.protectedDataWillBecomeUnavailableNotification,
                    fetchActivityMonitorTask.notification,
                    processingActivityMonitorTask.notification,
                ]

                for await notificationName in center.mergeNotifications(named: notificationNames).map(\.name) {
                    logger.log("Received \(notificationName.rawValue, privacy: .public)")

                    let oldState = state

                    switch notificationName {
                    case UIApplication.didEnterBackgroundNotification:
                        assert(app.applicationState == .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate(for: backgroundGracePeriod)

                    case UIApplication.willEnterForegroundNotification:
                        assert(app.applicationState != .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate()

                    case UIApplication.protectedDataDidBecomeAvailableNotification:
                        assert(app.applicationState == .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate(for: backgroundGracePeriod)

                    case UIApplication.protectedDataWillBecomeUnavailableNotification:
                        assert(app.applicationState == .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate(for: lockGracePeriod)

                    case fetchActivityMonitorTask.notification,
                         processingActivityMonitorTask.notification:

                        if app.applicationState == .background {
                            if app.isProtectedDataAvailable {
                                // Running in background while device is unlocked
                                state.activate(for: backgroundGracePeriod)
                            } else {
                                // Running in background while device is locked
                                state.deactivate()
                            }
                        } else {
                            // Active in foreground
                            assert(app.isProtectedDataAvailable, "expected protected data to be available")
                            assert(state.isActive, "expected to already be active")
                            assert(!state.hasExpiration, "expected to not have expiration")
                            state.activate()
                        }

                    default:
                        assertionFailure("unexpected notification: \(notificationName.rawValue)")
                    }

                    // It would be nice to do this in the state didSet hook, but we need async
                    await rescheduleBackgroundTasks(oldState: oldState, newState: state)
                }

                try await driftTask

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

    private func rescheduleBackgroundTasks(oldState: TimerState<UTCClock>, newState: TimerState<UTCClock>) async {
        if newState.hasExpiration {
            let taskBeginDate = UTCClock.Instant.now.advanced(by: backgroundTaskInterval).date
            await fetchActivityMonitorTask.reschedule(for: taskBeginDate)
            await processingActivityMonitorTask.reschedule(for: taskBeginDate)
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fetchActivityMonitor"]
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"processingActivityMonitor"]
        } else if oldState.hasExpiration {
            await fetchActivityMonitorTask.cancel()
            await processingActivityMonitorTask.cancel()
        }
    }
}

#endif
