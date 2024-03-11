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
    @StateObject private var activityMonitor: ActivityMonitor
    @State private var statusBarButton: NSStatusBarButton?

    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    init(userIdleSeconds: TimeInterval) {
        let activityMonitor = ActivityMonitor(userIdleSeconds: userIdleSeconds)
        _activityMonitor = StateObject(wrappedValue: activityMonitor)
    }

    var body: some View {
        Group {
            if let startDate = self.activityMonitor.startDate {
                MenuBarTimelineView(.periodic(from: startDate, by: textRefreshRate)) { context in
                    let duration = activityMonitor.duration(to: context.date)
                    Text(duration, format: .abbreviatedDuration)
                }
            } else {
                Text(.seconds(0), format: .abbreviatedDuration)
            }
        }
        .onAppear {
            self.statusBarButton = findStatusBarItem()?.button
        }
        .onChange(of: activityMonitor.isIdle) { isIdle in
            assert(self.statusBarButton != nil)
            self.statusBarButton?.appearsDisabled = isIdle
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
    @StateObject private var openOnLogin = LoginItem.mainApp

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
