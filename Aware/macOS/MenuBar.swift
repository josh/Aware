//
//  MenuBar.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import SwiftUI

struct MenuBar: Scene {
    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: TimeInterval = 120.0

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            TimerMenuBarLabel(userIdleSeconds: self.userIdleSeconds)
        }
    }
}

struct TimerMenuBarLabel: View {
    @StateObject private var activityTimer: ActivityTimer
    @State private var statusBarButton: NSStatusBarButton?

    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    init(userIdleSeconds: TimeInterval) {
        let activityTimer = ActivityTimer(userIdleSeconds: userIdleSeconds)
        _activityTimer = StateObject(wrappedValue: activityTimer)
    }

    var body: some View {
        Group {
            switch self.activityTimer.state {
            case .idle:
                Text(0.0, format: .abbreviatedTimeInterval)
            case let .active(startDate):
                MenuBarTimelineView(.periodic(from: startDate, by: textRefreshRate)) { context in
                    Text(context.date.timeIntervalSince(startDate), format: .abbreviatedTimeInterval)
                }
            }
        }
        .onAppear {
            self.statusBarButton = findStatusBarItem()?.button
        }
        .onChange(of: activityTimer.idle) { idle in
            assert(self.statusBarButton != nil)
            self.statusBarButton?.appearsDisabled = idle
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
    @StateObject var openOnLogin = LoginItem.mainApp

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
