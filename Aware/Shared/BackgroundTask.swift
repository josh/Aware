//
//  BackgroundTask.swift
//  Aware
//
//  Created by Joshua Peek on 3/23/24.
//

import BackgroundTasks
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "BackgroundTask")

@available(macOS, unavailable)
struct BackgroundTask {
    let identifier: String
    let notificationName: Notification.Name
    private let taskRequestType: TaskRequestType

    static func appRefresh(_ identifier: String) -> Self {
        return BackgroundTask(identifier: identifier, taskRequestType: .appRefresh)
    }

    static func processing(
        _ identifier: String,
        requiresExternalPower: Bool = false,
        requiresNetworkConnectivity: Bool = false
    ) -> Self {
        return BackgroundTask(
            identifier: identifier,
            taskRequestType: .processing(
                requiresExternalPower: requiresExternalPower,
                requiresNetworkConnectivity: requiresNetworkConnectivity
            )
        )
    }

    enum TaskRequestType {
        case appRefresh
        case processing(requiresExternalPower: Bool, requiresNetworkConnectivity: Bool)
    }

    init(identifier: String, taskRequestType: TaskRequestType) {
        self.identifier = identifier
        self.taskRequestType = taskRequestType
        notificationName = Notification.Name(identifier)
    }

    func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
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

    func reschedule(for beginDate: Date) {
        cancel()
        schedule(for: beginDate)
    }

    func reschedule(after duration: Duration) {
        cancel()
        schedule(after: duration)
    }

    func schedule(after duration: Duration) {
        let instant = UTCClock.Instant.now.advanced(by: duration)
        schedule(for: instant.date)
    }

    func schedule(for beginDate: Date) {
        let request = self.request
        request.earliestBeginDate = beginDate

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled \(identifier, privacy: .public) task after \(beginDate, privacy: .public)")
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
}

@available(macOS, unavailable)
extension Scene {
    func backgroundTask(_ task: BackgroundTask) -> some Scene {
        return backgroundTask(.appRefresh(task.identifier)) {
            logger.log("Starting background task: \(task.identifier, privacy: .public)")
            let notification = Notification(name: task.notificationName, object: BGTaskScheduler.shared)
            NotificationCenter.default.post(notification)
            logger.log("Finished background task: \(task.identifier, privacy: .public)")
        }
    }
}
