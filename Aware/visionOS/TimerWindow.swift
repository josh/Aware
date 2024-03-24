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
    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        .defaultSize(width: 240, height: 135)
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        .backgroundTask(fetchActivityMonitorTask)
        .backgroundTask(processingActivityMonitorTask)
    }
}

#endif
