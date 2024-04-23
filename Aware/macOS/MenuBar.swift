//
//  MenuBar.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import OSLog
import ServiceManagement
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
            TimerMenuBarLabel(userIdle: userIdle, includeSeconds: false)
        }
    }
}

struct TimerMenuBarLabel: View {
    let userIdle: Duration

    var includeSeconds: Bool = false

    /// Set text refresh rate to 60 seconds, when minutes are shown
    private var textRefreshRate: TimeInterval { includeSeconds ? 1.0 : 60.0 }

    private var timerFormat: TimerFormatStyle {
        TimerFormatStyle(style: .condensedAbbreviated, includeSeconds: includeSeconds)
    }

    @State private var timerState = TimerState()
    @State private var statusBarButton: NSStatusBarButton?

    var body: some View {
        Group {
            if let start = timerState.start {
                MenuBarTimelineView(.periodic(from: start.date, by: textRefreshRate)) { context in
                    let duration = timerState.duration(to: UTCClock.Instant(context.date))
                    Text(duration, format: timerFormat)
                }
            } else {
                Text(.seconds(0), format: timerFormat)
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
    @State private var lastLoginItemRegistration: Result<Bool, Error>?

    var body: some View {
        Toggle("Open at Login", isOn: openAtLogin)
            .toggleStyle(.checkbox)
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }

    var openAtLogin: Binding<Bool> {
        .init {
            switch lastLoginItemRegistration {
            case let .success(enabled): return enabled
            default: return SMAppService.mainApp.status == .enabled
            }
        } set: { enabled in
            lastLoginItemRegistration = Result {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return SMAppService.mainApp.status == .enabled
            }
        }
    }
}

#endif
