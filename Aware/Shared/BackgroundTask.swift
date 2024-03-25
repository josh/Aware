//
//  BackgroundTask.swift
//  Aware
//
//  Created by Joshua Peek on 3/23/24.
//

import BackgroundTasks
import OSLog
import SwiftUI

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "BackgroundTask"
)

@available(macOS, unavailable)
actor BackgroundTask {
    enum TaskRequestType {
        case appRefresh
        case processing(requiresExternalPower: Bool, requiresNetworkConnectivity: Bool)
    }

    struct ScheduledTask {
        let submittedAt: Date
        let earliestBeginAt: Date
    }

    struct RanTask {
        let task: ScheduledTask?
        let ranAt: Date
    }

    let identifier: String
    let notification: Notification.Name
    private let taskRequestType: TaskRequestType

    var scheduledTask: ScheduledTask?
    var lastRanTask: RanTask?

    static func appRefresh(_ identifier: String) -> BackgroundTask {
        BackgroundTask(identifier: identifier, taskRequestType: .appRefresh)
    }

    static func processing(
        _ identifier: String,
        requiresExternalPower: Bool = false,
        requiresNetworkConnectivity: Bool = false
    ) -> BackgroundTask {
        BackgroundTask(
            identifier: identifier,
            taskRequestType: .processing(
                requiresExternalPower: requiresExternalPower,
                requiresNetworkConnectivity: requiresNetworkConnectivity
            )
        )
    }

    init(identifier: String, taskRequestType: TaskRequestType) {
        self.identifier = identifier
        self.taskRequestType = taskRequestType
        notification = Notification.Name(identifier)
    }

    nonisolated func schedule(for beginDate: Date) {
        Task { await self._schedule(for: beginDate) }
    }

    nonisolated func reschedule(for beginDate: Date) {
        Task { await self._reschedule(for: beginDate) }
    }

    nonisolated func schedule(after duration: Duration) {
        let instant = UTCClock.Instant.now.advanced(by: duration)
        schedule(for: instant.date)
    }

    nonisolated func reschedule(after duration: Duration) {
        let instant = UTCClock.Instant.now.advanced(by: duration)
        reschedule(for: instant.date)
    }

    nonisolated func cancel() {
        Task { await self._cancel() }
    }

    private var request: BGTaskRequest {
        switch taskRequestType {
        case .appRefresh:
            return BGAppRefreshTaskRequest(identifier: identifier)
        case let .processing(requiresExternalPower, requiresNetworkConnectivity):
            let request = BGProcessingTaskRequest(identifier: identifier)
            request.requiresExternalPower = requiresExternalPower
            request.requiresNetworkConnectivity = requiresNetworkConnectivity
            return request
        }
    }

    fileprivate func run() {
        let identifier = self.identifier
        logger.log("Starting background task: \(identifier, privacy: .public)")

        if let scheduledTask {
            let submittedAgo: Duration = UTCClock.Instant(scheduledTask.submittedAt).duration(to: .now)
            let earliestBeginAgo: Duration = UTCClock.Instant(scheduledTask.earliestBeginAt).duration(
                to: .now)
            logger.log("Background submitted at \(scheduledTask.submittedAt), \(submittedAgo) ago")
            logger.log(
                "Requested to run after \(scheduledTask.earliestBeginAt), \(earliestBeginAgo) after")
        } else {
            logger.error(
                "Running background task, but no scheduled \(identifier, privacy: .public) task noted")
        }
        lastRanTask = RanTask(task: scheduledTask, ranAt: .now)

        let notification = Notification(name: self.notification, object: self)
        logger.log("Posting \(notification.name.rawValue) notification")
        NotificationCenter.default.post(notification)

        logger.log("Finished background task: \(identifier, privacy: .public)")
    }

    private func _cancel() async {
        let pendingCount = await countPendingTaskRequests()
        guard pendingCount > 0 else {
            logger.debug("No scheduled tasks to cancel")
            return
        }
        assert(pendingCount <= 1, "more than one background task was scheduled")

        scheduledTask = nil
        let identifier = identifier
        logger.info("Canceling \(pendingCount) \(identifier, privacy: .public) task")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }

    private func _reschedule(for beginDate: Date) async {
        let earliestBeginAt: Date = await earliestPendingTaskRequestBeginDate() ?? .distantPast
        guard beginDate > earliestBeginAt.addingTimeInterval(60) else {
            let identifier = identifier
            logger.debug("\(identifier, privacy: .public) task already scheduled for \(beginDate)")
            return
        }

        await _cancel()
        _schedule(for: beginDate)
    }

    private func _schedule(for beginDate: Date) {
        let identifier = identifier
        let request = request

        request.earliestBeginDate = beginDate

        do {
            try BGTaskScheduler.shared.submit(request)
            scheduledTask = ScheduledTask(submittedAt: .now, earliestBeginAt: beginDate)
            logger.info(
                "Scheduled \(identifier, privacy: .public) task after \(beginDate, privacy: .public)")
        } catch let error as BGTaskScheduler.Error {
            switch error.code {
            case .unavailable:
                #if !targetEnvironment(simulator)
                logger.info("App can’t schedule background work")
                #endif
            case .tooManyPendingTaskRequests:
                logger.error("Too many pending \(identifier, privacy: .public) tasks requested")
            case .notPermitted:
                logger.error("App isn’t permitted to launch \(identifier, privacy: .public) task")
            @unknown default:
                logger.error("Unknown error scheduling \(identifier, privacy: .public) task: \(error)")
            }
        } catch {
            logger.error("Unknown error scheduling \(identifier, privacy: .public) task: \(error)")
        }
    }

    private nonisolated func countPendingTaskRequests() async -> Int {
        await BGTaskScheduler.shared.pendingTaskRequests().filter { request in
            request.identifier == self.identifier
        }.count
    }

    private nonisolated func earliestPendingTaskRequestBeginDate() async -> Date? {
        await BGTaskScheduler.shared.pendingTaskRequests().compactMap(\.earliestBeginDate).min()
    }
}

@available(macOS, unavailable)
extension Scene {
    func backgroundTask(_ task: BackgroundTask) -> some Scene {
        backgroundTask(.appRefresh(task.identifier)) {
            await task.run()
        }
    }
}
