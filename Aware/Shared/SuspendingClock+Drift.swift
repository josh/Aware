//
//  SuspendingClock+Drift.swift
//  Aware
//
//  Created by Joshua Peek on 3/23/24.
//

import Foundation
import OSLog

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "SuspendingClock+Drift"
)

#if canImport(AppKit)
import AppKit

private let notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter

private let notifications: [Notification.Name] = [
    NSWorkspace.willSleepNotification,
    NSWorkspace.didWakeNotification,
    NSWorkspace.screensDidSleepNotification,
    NSWorkspace.screensDidWakeNotification,
    NSWorkspace.willPowerOffNotification,
]

#elseif canImport(UIKit)
import UIKit

private let notificationCenter: NotificationCenter = .default

private let notifications: [Notification.Name] = [
    UIApplication.nonisolatedDidEnterBackgroundNotification,
    UIApplication.nonisolatedWillEnterForegroundNotification,
]

#endif

extension SuspendingClock {
    /// Monitor the system's suspending clock's drift compared to the system's continous clock.
    /// When the drift exceeds the threshold, return from this async function.
    /// - Parameter threshold: The minium duration of acceptable drift
    /// - Throws: `CancellationError` when task is canceled
    /// - Returns: The drift duration above the `threshold`
    @discardableResult
    func monitorDrift(threshold: Duration) async throws -> Duration {
        let continuousClock = ContinuousClock()
        let suspendingClock = self

        let continuousStart = continuousClock.now
        let suspendingStart = suspendingClock.now
        var drift: Duration = .zero

        for await notification in notificationCenter.mergeNotifications(named: notifications) {
            logger.log("Received \(notification.name.rawValue, privacy: .public)")

            let continuousDuration = continuousClock.now - continuousStart
            assert(continuousDuration > .zero)

            let suspendingDuration = suspendingClock.now - suspendingStart
            assert(suspendingDuration > .zero)

            drift = continuousDuration - suspendingDuration
            assert(drift >= .milliseconds(-1), "suspending clock running ahead of continuous clock")

            logger.debug(
                """
                continuous \(continuousDuration, privacy: .public) - \
                suspending \(suspendingDuration, privacy: .public) = \
                drift \(drift, privacy: .public)
                """
            )

            if drift > threshold {
                logger.log("suspending drift exceeded threshold: \(drift, privacy: .public)")
                break
            }

            try Task.checkCancellation()
        }

        try Task.checkCancellation()
        return drift
    }
}
