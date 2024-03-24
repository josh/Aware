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

@MainActor
class ActivityMonitor {
    /// The minimum number of seconds to schedule between background tasks.
    let backgroundTaskInterval: Duration = .minutes(5)

    /// The duration the app can be in the background and be considered active if it's opened again.
    let backgroundGracePeriod: Duration = .hours(2)

    /// The duration after locking the device it can be considered active if it's unlocked again.
    let lockGracePeriod: Duration = .minutes(1)

    /// The max duration to allow the suspending clock to drift from the continuous clock.
    let maxSuspendingClockDrift: Duration = .seconds(10)

    var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.log("State changed from \(oldValue, privacy: .public) to \(newValue, privacy: .public)")
            updatesChannel.send(newValue)

            if newValue.hasExpiration {
                fetchActivityMonitorTask.reschedule(after: backgroundTaskInterval)
                processingActivityMonitorTask.reschedule(after: backgroundTaskInterval)
                // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fetchActivityMonitor"]
                // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"processingActivityMonitor"]
            } else if oldValue.hasExpiration {
                fetchActivityMonitorTask.cancel()
                processingActivityMonitorTask.cancel()
            }
        }
    }

    typealias Updates = WatchChannel<TimerState<UTCClock>>.Subscription
    private var updatesChannel = WatchChannel<TimerState<UTCClock>>()

    var stateUpdates: Updates {
        updatesChannel.subscribe()
    }

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task { [weak self, maxSuspendingClockDrift] in
            do {
                logger.debug("Starting ActivityMonitor update task")

                let center = NotificationCenter.default

                async let driftTask: () = {
                    while true {
                        try await SuspendingClock().monitorDrift(threshold: maxSuspendingClockDrift)
                        center.post(name: .suspendingClockDriftNotification, object: nil)
                    }
                }()

                let app = UIApplication.shared

                // Set initial state
                if let self {
                    assert(app.applicationState != .background)
                    assert(app.isProtectedDataAvailable)
                    assert(self.state.isIdle)
                    state.activate()
                } else {
                    assertionFailure("task cancelled before initialization")
                }

                let notificationNames = [
                    UIApplication.didEnterBackgroundNotification,
                    UIApplication.willEnterForegroundNotification,
                    UIApplication.protectedDataDidBecomeAvailableNotification,
                    UIApplication.protectedDataWillBecomeUnavailableNotification,
                    fetchActivityMonitorTask.notification,
                    processingActivityMonitorTask.notification,
                    .suspendingClockDriftNotification,
                ]

                for await notificationName in center.mergeNotifications(named: notificationNames).map({
                    notification in notification.name
                }) {
                    logger.log("Received \(notificationName.rawValue, privacy: .public)")
                    guard let self else { break }

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
                        // TODO: But if I'm in the background, then maybe activate with grace?
                        assert(app.applicationState == .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate()

                    case UIApplication.protectedDataWillBecomeUnavailableNotification:
                        assert(app.applicationState == .background)
                        assert(app.isProtectedDataAvailable)
                        state.activate(for: lockGracePeriod)

                    case fetchActivityMonitorTask.notification,
                         processingActivityMonitorTask.notification:

                        if app.applicationState == .background {
                            if app.isProtectedDataAvailable {
                                state.activate(for: backgroundGracePeriod)
                            } else {
                                state.deactivate()
                            }
                        } else {
                            // TODO: This branch maybe useless
                            assert(app.isProtectedDataAvailable, "expected protected data to be available")
                            assert(state.isActive, "expected to already be active")
                            assert(!state.hasExpiration, "expected to not have expiration")
                            state.activate()
                        }

                    case .suspendingClockDriftNotification:
                        state.deactivate()

                    default:
                        assertionFailure("unexpected notification name: \(notificationName)")
                    }
                }

                try await driftTask

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

fileprivate extension Notification.Name {
    static let suspendingClockDriftNotification = Notification.Name(
        "suspendingClockDriftNotification")
}

#endif
