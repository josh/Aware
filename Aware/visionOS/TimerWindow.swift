//
//  TimerWindow.swift
//  Aware
//
//  Created by Joshua Peek on 3/9/24.
//

#if os(visionOS)

import SwiftUI

struct TimerWindow: Scene {
    @State private var activityMonitor = ActivityMonitor()

    var body: some Scene {
        WindowGroup {
            TimerView(activityMonitor: activityMonitor)
        }
        .defaultSize(width: 240, height: 135)
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        .backgroundTask(.appRefresh("fetchActivityMonitor")) {
            activityMonitor.refresh()
        }
        .backgroundTask(.appRefresh("processingActivityMonitor")) {
            activityMonitor.refresh()
        }
    }
}

#endif