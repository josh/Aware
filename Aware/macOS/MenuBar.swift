//
//  MenuBar.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import OSLog
import SwiftUI

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "MenuBar"
)

struct MenuBar: Scene {
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            TimerMenuBarLabel()
        }
    }
}

struct TimerMenuBarLabel: View {
    @State private var timerState = TimerState()
    @State private var statusItem: NSStatusItem?

    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: Int = 120

    @AppStorage("formatStyle") private var timerFormatStyle: TimerFormatStyle.Style = .condensedAbbreviated
    @AppStorage("showSeconds") private var showSeconds: Bool = false

    private var timerFormat: TimerFormatStyle {
        TimerFormatStyle(style: timerFormatStyle, showSeconds: showSeconds)
    }

    private var activityMonitorConfiguration: ActivityMonitor.Configuration {
        ActivityMonitor.Configuration(
            userIdle: .seconds(max(1, userIdleSeconds))
        )
    }

    var body: some View {
        Group {
            if let start = timerState.start {
                MenuBarTimelineView(.periodic(from: start.date, by: timerFormat.refreshInterval)) { context in
                    let duration = timerState.duration(to: UTCClock.Instant(context.date))
                    Text(duration, format: timerFormat)
                }
            } else {
                Text(.seconds(0), format: timerFormat)
            }
        }
        .task(id: activityMonitorConfiguration) {
            let activityMonitor = ActivityMonitor(initialState: timerState, configuration: activityMonitorConfiguration)
            logger.log("Starting ActivityMonitor updates task: \(timerState, privacy: .public)")
            for await state in activityMonitor.updates() {
                logger.log("Received ActivityMonitor state: \(state, privacy: .public)")
                timerState = state
            }
            logger.log("Finished ActivityMonitor updates task: \(timerState, privacy: .public)")
        }
        .bindStatusItem($statusItem)
        .onChange(of: timerState.isIdle) { _, isIdle in
            assert(statusItem?.button != nil, "missing statusItem button")
            statusItem?.button?.appearsDisabled = isIdle
        }
    }
}

struct MenuBarContentView: View {
    var body: some View {
        SettingsLink()
            .keyboardShortcut(",")
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

#endif
