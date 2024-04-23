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
    @State private var statusBarButton: NSStatusBarButton?

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
            logger.info("Starting ActivityMonitor updates task: \(timerState, privacy: .public)")
            for await state in activityMonitor.updates() {
                logger.info("Received ActivityMonitor state: \(state, privacy: .public)")
                timerState = state
            }
            logger.info("Finished ActivityMonitor updates task: \(timerState, privacy: .public)")
        }
        .onAppear {
            statusBarButton = findStatusBarItem()?.button
        }
        .onChange(of: timerState.isIdle) { _, isIdle in
            assert(statusBarButton != nil)
            statusBarButton?.appearsDisabled = isIdle
        }
    }
}

// Hack to get underlying NSStatusItem for MenuBarExtra
// https://github.com/orchetect/MenuBarExtraAccess/blob/main/Sources/MenuBarExtraAccess/MenuBarExtraUtils.swift
@MainActor
private func findStatusBarItem() -> NSStatusItem? {
    for window in NSApp.windows where window.className == "NSStatusBarWindow" {
        return window.value(forKey: "statusItem") as? NSStatusItem
    }
    assertionFailure("couldn't find NSStatusBarWindow")
    return nil
}

struct MenuBarContentView: View {
    var body: some View {
        SettingsLink()
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

#endif
