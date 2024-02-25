//
//  ActivityTimer.swift
//  Aware
//
//  Created by Joshua Peek on 2/23/24.
//

#if os(visionOS)

import BackgroundTasks
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
    let backgroundGracePeriod: TimeInterval = 2 * 60 * 60

    private enum State: CustomStringConvertible, Equatable {
        case idle
        case grace(Date, Date)
        case active(Date)

        /// Enter active state preserving timer start date. Reset date to now if idle or grace has expired.
        var activate: Self {
            .active(startDate ?? .now)
        }

        func extendGracePeriod(_ expireAt: Date) -> Self {
            .grace(startDate ?? .now, expireAt)
        }

        /// Get valid timer start date. Return `nil` if idle or grace has expired.
        var startDate: Date? {
            switch self {
            case .idle:
                return nil
            case let .grace(startDate, expireDate):
                if Date.now < expireDate {
                    return startDate
                } else {
                    return nil
                }
            case let .active(startDate):
                return startDate
            }
        }

        var description: String {
            switch self {
            case .idle:
                return "idle"
            case let .grace(startDate, expireDate):
                if Date.now < expireDate {
                    let duration = Date.now.timeIntervalSince(startDate)
                    let expires = expireDate.timeIntervalSince(.now)
                    return "grace(\(duration.formatted(.timeDuration)), expires in \(expires.formatted(.timeDuration)))"
                } else {
                    return "grace(expired)"
                }
            case let .active(startDate):
                let duration = Date.now.timeIntervalSince(startDate)
                return "active(\(duration.formatted(.timeDuration)))"
            }
        }
    }

    private var state: State = .active(.now) {
        didSet {
            let newValue = state
            logger.info("state changed from \(oldValue) to \(newValue)")

            switch (oldValue, newValue) {
            case (_, .grace):
                scheduleBackgroundTasks()
            case (.grace, _):
                cancelBackgroundTasks()
            default: ()
            }

            if case let .grace(_, expireDate) = newValue {
                assert(Date.now < expireDate, "grace set to expired value")
            }
        }
    }

    private enum ScenePhase: String {
        case locked
        case background
        case foreground

        static var current: Self {
            let app = UIApplication.shared
            if !app.isProtectedDataAvailable {
                assert(app.applicationState == .background, "locked can't be in foreground")
                return .locked
            } else if app.applicationState == .background {
                return .background
            } else {
                return .foreground
            }
        }
    }

    private init() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("didEnterBackgroundNotification")
            update(scenePhase: .background)
        }

        notificationCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("willEnterForegroundNotification")
            update(scenePhase: .foreground)
        }

        notificationCenter.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("protectedDataDidBecomeAvailableNotification")
            update(scenePhase: .current)
        }

        notificationCenter.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("protectedDataWillBecomeUnavailableNotification")
            update(scenePhase: .locked)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshIdentifier, using: .main) { [weak self] task in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("\(backgroundAppRefreshIdentifier)")
            self.update(scenePhase: .current)
            task.setTaskCompleted(success: true)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundProcessingIdentifier, using: .main) { [weak self] task in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            logger.debug("\(backgroundProcessingIdentifier)")
            self.update(scenePhase: .current)
            task.setTaskCompleted(success: true)
        }
    }

    var startDate: Date? {
        state.startDate
    }

    func timeIntervalFrom(_ endDate: Date) -> TimeInterval {
        if let startDate {
            return endDate.timeIntervalSince(startDate)
        } else {
            return 0.0
        }
    }

    private func update(scenePhase: ScenePhase) {
        switch scenePhase {
        case .locked:
            state = .idle
        case .background:
            state = state.extendGracePeriod(.now.addingTimeInterval(backgroundGracePeriod))
        case .foreground:
            state = state.activate
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
