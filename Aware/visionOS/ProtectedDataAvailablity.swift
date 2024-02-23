//
//  ProtectedDataAvailablity.swift
//  Aware
//
//  Created by Joshua Peek on 2/18/24.
//

#if canImport(UIKit)

import BackgroundTasks
import os.log
import UIKit

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ProtectedDataAvailablity")

@Observable class ProtectedDataAvailablity {
    static let appRefreshIdentifier = "checkProtectedDataAvailablity"
    static let backgroundRefreshInterval: TimeInterval = 5 * 60 // 5 minutes

    var isAvailable: Bool = true

    private var availableObserver: NSObjectProtocol?
    private var unavailableObserver: NSObjectProtocol?

    init() {
        let notificationCenter = NotificationCenter.default

        isAvailable = true

        availableObserver = notificationCenter.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            if self.isAvailable != true {
                self.isAvailable = true
            }
        }

        unavailableObserver = notificationCenter.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            if self.isAvailable != false {
                self.isAvailable = false
            }
        }
    }

    deinit {
        if let availableObserver {
            NotificationCenter.default.removeObserver(availableObserver)
        }
        if let unavailableObserver {
            NotificationCenter.default.removeObserver(unavailableObserver)
        }
    }

    nonisolated func cancelBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.appRefreshIdentifier)
    }

    nonisolated func scheduleBackgroundCheck() -> Bool {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.appRefreshIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: Self.appRefreshIdentifier)
        let beginDate: Date = .now.addingTimeInterval(Self.backgroundRefreshInterval)
        request.earliestBeginDate = beginDate
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("Background task scheduled for \(beginDate)")
            return true
        } catch let error as BGTaskScheduler.Error {
            switch error.code {
            case .notPermitted:
                assertionFailure("App isn’t permitted to schedule the task")
                logger.error("App isn’t permitted to schedule the task: \(error)")
            case .tooManyPendingTaskRequests:
                logger.warning("There are too many pending tasks of the type requested: \(error)")
            case .unavailable:
                logger.info("App can’t schedule background work: \(error)")
            @unknown default:
                assertionFailure("Unknown BGTaskScheduler.Error")
                logger.warning("Unknown BGTaskScheduler.Error: \(error)")
            }
            return false
        } catch {
            assertionFailure("Unexpected BGTaskScheduler error")
            logger.error("Unexpected BGTaskScheduler error: \(error)")
            return false
        }
    }

    @MainActor
    func appRefreshCheck() {
        let isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable

        if isProtectedDataAvailable != isAvailable {
            isAvailable = isProtectedDataAvailable
        }

        if isProtectedDataAvailable {
            logger.info("Device unlocked, continue polling")
            if !scheduleBackgroundCheck() {
                logger.warning("Couldn't schedule next checkProtectedDataAvailablity")
            }
        } else {
            logger.info("Device locked, stop polling")
        }
    }
}

#endif
