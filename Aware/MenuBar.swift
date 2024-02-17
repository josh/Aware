//
//  MenuBar.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

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

    init(userIdleSeconds: TimeInterval) {
        let activityTimer = ActivityTimer(userIdleSeconds: userIdleSeconds, pollInterval: 60.0)
        _activityTimer = StateObject(wrappedValue: activityTimer)
    }

    var body: some View {
        Text(activityTimer.duration.formatted(.custom))
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
