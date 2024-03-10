//
//  ActivityTimer.swift
//  Aware
//
//  Created by Joshua Peek on 2/23/24.
//

#if os(visionOS)

import BackgroundTasks
import Combine
import os.log
import UIKit

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityTimer")

@Observable class ActivityTimer {
    static let shared = ActivityTimer()

    /// The identifier for BGAppRefreshTaskRequest
    let backgroundAppRefreshIdentifier = "fetchActivityTimer"

    /// The identifier for BGProcessingTaskRequest
    let backgroundProcessingIdentifier = "processingActivityTimer"

    /// The minimum number of seconds to schedule between background tasks.
    let backgroundTaskInterval: TimeInterval = 5 * 60

    /// The number of seconds the app can be in the background and be considered active if it's opened again.
    let backgroundGracePeriod: Duration = .seconds(2 * 60 * 60)

    /// The number of seconds after locking the device it can be considered active if it's unlocked again.
    let lockGracePeriod: Duration = .seconds(2 * 60)

    var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.info("state changed from \(oldValue) to \(newValue)")

            if newValue.hasExpiration {
                scheduleBackgroundTasks()
            } else if oldValue.hasExpiration {
                cancelBackgroundTasks()
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("entered background")
                self.state.activate(for: backgroundGracePeriod)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("entered foreground")
                self.state.activate()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("protected data available")
                updateState()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("protected data unavailable")
                self.state.activate(for: lockGracePeriod)
            }
            .store(in: &cancellables)

        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshIdentifier, using: .main) { [weak self] task in
            guard let self = self else { return }
            logger.info("background app refresh")
            updateState()
            task.setTaskCompleted(success: true)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundProcessingIdentifier, using: .main) { [weak self] task in
            guard let self = self else { return }
            logger.info("background processing")
            updateState()
            task.setTaskCompleted(success: true)
        }
    }

    var startDate: Date? {
        state.start?.date
    }

    func duration(to endDate: Date) -> Duration {
        state.duration(to: .init(endDate))
    }

    private func updateState() {
        let app = UIApplication.shared
        if !app.isProtectedDataAvailable {
            assert(app.applicationState == .background, "locked can't be in foreground")
            state.deactivate()
        } else if app.applicationState == .background {
            state.activate(for: backgroundGracePeriod)
        } else {
            state.activate()
        }
    }

    private func scheduleBackgroundTasks() {
        cancelBackgroundTasks()
        scheduleBackgroundRefreshTask()
        scheduleBackgroundProcessingTask()
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"fetchActivityTimer"]
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"processingActivityTimer"]
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
            logger.debug("Scheduled task with identifier \(request.identifier) after \(request.earliestBeginDate?.description ?? "(nil)")")
        } catch {
            logger.error("Error scheduling task with identifier \(request.identifier): \(error)")
        }
    }
}

#endif
