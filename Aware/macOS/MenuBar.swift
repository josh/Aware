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

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "MenuBar")

struct MenuBar: Scene {
    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: TimeInterval = 120.0

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            TimerMenuBarLabel(userIdleSeconds: userIdleSeconds)
        }
    }
}

struct TimerMenuBarLabel: View {
    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    let userIdleSeconds: TimeInterval

    @State private var activityMonitorState = TimerState(clock: UTCClock())
    @State private var statusBarButton: NSStatusBarButton?

    var body: some View {
        Group {
            if let startDate = activityMonitorState.start?.date {
                MenuBarTimelineView(.periodic(from: startDate, by: textRefreshRate)) { context in
                    let duration = activityMonitorState.duration(to: UTCClock.Instant(context.date))
                    Text(duration, format: .abbreviatedDuration)
                }
            } else {
                Text(.seconds(0), format: .abbreviatedDuration)
            }
        }
        .task {
            logger.debug("Starting observe ActivityMonitor state changes")
            let activityMonitor = ActivityMonitor(userIdleSeconds: userIdleSeconds)
            for await state in activityMonitor.stateUpdates {
                let oldState = activityMonitorState
                logger.log("Observed ActivityMonitor state change from \(oldState, privacy: .public) to \(state, privacy: .public)")
                activityMonitorState = state
            }
            logger.debug("Finished observing ActivityMonitor state changes")
        }
        .onAppear {
            statusBarButton = findStatusBarItem()?.button
        }
        .onChange(of: activityMonitorState.isIdle) { isIdle in
            assert(statusBarButton != nil)
            statusBarButton?.appearsDisabled = isIdle
        }
    }
}

// Hack to get underlying NSStatusItem for MenuBarExtra
// https://github.com/orchetect/MenuBarExtraAccess/blob/main/Sources/MenuBarExtraAccess/MenuBarExtraUtils.swift
@MainActor
private func findStatusBarItem() -> NSStatusItem? {
    for window in NSApp.windows {
        if window.className == "NSStatusBarWindow" {
            return window.value(forKey: "statusItem") as? NSStatusItem
        }
    }
    assertionFailure("couldn't find NSStatusBarWindow")
    return nil
}

struct MenuBarContentView: View {
    @ObservedObject private var openOnLogin = LoginItem.mainApp

    var body: some View {
        Toggle("Open at Login", isOn: $openOnLogin.isEnabled)
            .toggleStyle(.checkbox)
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

#endif
