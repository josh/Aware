//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/23/24.
//

#if os(visionOS)

import BackgroundTasks
import Combine
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityMonitor")

@Observable class ActivityMonitor {
    /// The identifier for BGAppRefreshTaskRequest
    let backgroundAppRefreshIdentifier = "fetchActivityMonitor"

    /// The identifier for BGProcessingTaskRequest
    let backgroundProcessingIdentifier = "processingActivityMonitor"

    /// The minimum number of seconds to schedule between background tasks.
    let backgroundTaskInterval: TimeInterval = 5 * 60

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

            if newValue.hasExpiration {
                scheduleBackgroundTasks()
            } else if oldValue.hasExpiration {
                cancelBackgroundTasks()
            }
        }
    }

    @ObservationIgnored
    private var clocks: (continuous: ContinuousClock.Instant, suspending: SuspendingClock.Instant) = (.now, .now)

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.log("Received didEnterBackgroundNotification")
                guard let self = self else { return }
                checkClockDrift()
                self.state.activate(for: backgroundGracePeriod)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.log("Received willEnterForegroundNotification")
                guard let self = self else { return }
                checkClockDrift()
                self.state.activate()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.log("Received protectedDataDidBecomeAvailableNotification")
                guard let self = self else { return }
                update()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.log("Received protectedDataWillBecomeUnavailableNotification")
                guard let self = self else { return }
                self.state.activate(for: lockGracePeriod)
            }
            .store(in: &cancellables)
    }

    var startDate: Date? {
        state.start?.date
    }

    func duration(to endDate: Date) -> Duration {
        state.duration(to: .init(endDate))
    }

    private func checkClockDrift() {
        let continuousDuration = .now - clocks.continuous
        let suspendingDuration = .now - clocks.suspending
        let suspendingDrift = continuousDuration - suspendingDuration
        logger.debug("Suspending clock drift: \(suspendingDrift, privacy: .public)")

        if suspendingDrift > maxSuspendingClockDrift {
            logger.log("Exceeded max suspending clock drift: \(suspendingDrift, privacy: .public)")
            clocks = (.now, .now)
            state.deactivate()
        }
    }

    func update() {
        var logState = state
        logger.debug("Updating ActivityMonitor state: \(logState, privacy: .public)")
        let app = UIApplication.shared
        if !app.isProtectedDataAvailable {
            assert(app.applicationState == .background, "locked can't be in foreground")
            state.deactivate()
        } else if app.applicationState == .background {
            state.activate(for: backgroundGracePeriod)
        } else {
            state.activate()
        }
        logState = state
        logger.debug("Finished updating ActivityMonitor state: \(logState, privacy: .public)")
    }

    private func scheduleBackgroundTasks() {
        cancelBackgroundTasks()
        scheduleBackgroundRefreshTask()
        scheduleBackgroundProcessingTask()
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fetchActivityMonitor"]
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"processingActivityMonitor"]
    }

    private func cancelBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundAppRefreshIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundProcessingIdentifier)
    }

    private func scheduleBackgroundRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundAppRefreshIdentifier)
        let beginDate: Date = .now.addingTimeInterval(backgroundTaskInterval)
        request.earliestBeginDate = beginDate
        scheduleBackgroundTask(request: request)
    }

    private func scheduleBackgroundProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundProcessingIdentifier)
        let beginDate: Date = .now.addingTimeInterval(backgroundTaskInterval)
        request.earliestBeginDate = beginDate
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = false
        scheduleBackgroundTask(request: request)
    }

    private func scheduleBackgroundTask(request: BGTaskRequest) {
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled \(request.identifier, privacy: .public) task after \(request.earliestBeginDate?.description ?? "(nil)", privacy: .public)")
        } catch {
            logger.error("Error scheduling \(request.identifier, privacy: .public) task: \(error)")
        }
    }
}

#endif
