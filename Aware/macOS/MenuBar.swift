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
    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: Int = 120

    var userIdle: Duration {
        .seconds(max(1, userIdleSeconds))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            TimerMenuBarLabel(userIdle: userIdle)
        }
    }
}

struct TimerMenuBarLabel: View {
    let userIdle: Duration

    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    @State private var timerState = TimerState()
    @State private var statusBarButton: NSStatusBarButton?

    var body: some View {
        Group {
            if let start = timerState.start {
                MenuBarTimelineView(.periodic(from: start.date, by: textRefreshRate)) { context in
                    let duration = timerState.duration(to: UTCClock.Instant(context.date))
                    Text(duration, format: .abbreviatedDuration)
                }
            } else {
                Text(.seconds(0), format: .abbreviatedDuration)
            }
        }
        .task {
            for await state in ActivityMonitor(initialState: timerState, userIdle: userIdle).updates() {
                timerState = state
            }
        }
        .onAppear {
            statusBarButton = findStatusBarItem()?.button
        }
        .onChange(of: timerState.isIdle) { isIdle in
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
