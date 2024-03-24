//
//  TimerWindow.swift
//  Aware
//
//  Created by Joshua Peek on 3/9/24.
//

#if os(visionOS)

import OSLog
import SwiftUI

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "TimerWindow"
)

struct TimerWindow: Scene {
    private let activityMonitor = ActivityMonitor()

    var body: some Scene {
        WindowGroup {
            TimerView(activityMonitor: activityMonitor)
        }
        .defaultSize(width: 240, height: 135)
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        .backgroundTask(.appRefresh("fetchActivityMonitor")) {
            logger.log("Starting background task: fetchActivityMonitor")
            activityMonitor.update()
            logger.log("Finished background task: fetchActivityMonitor")
        }
        .backgroundTask(.appRefresh("processingActivityMonitor")) {
            logger.log("Starting background task: processingActivityMonitor")
            activityMonitor.update()
            logger.log("Finished background task: processingActivityMonitor")
        }
    }
}

#endif
