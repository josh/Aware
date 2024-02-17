//
//  AppDelegate.swift
//  Aware
//
//  Created by Joshua Peek on 12/06/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import AppKit
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var timerStart: Date = .init()

    // Redraw button every minute
    let buttonRefreshRate: TimeInterval = 60

    // Reference to installed global mouse event monitor
    var mouseEventMonitor: Any?

    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: TimeInterval = 120.0

    let openAtLoginMenuItem = NSMenuItem(
        title: "Open at Login",
        action: #selector(openAtLogin),
        keyEquivalent: ""
    )

    let quitMenuItem = NSMenuItem(
        title: "Quit Aware",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
    )

    lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(openAtLoginMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        menu.delegate = self
        return menu
    }()

    lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_: Notification) {
        statusItem.menu = menu

        updateButton()
        _ = Timer.scheduledTimer(withTimeInterval: buttonRefreshRate, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }
    }

    @objc func openAtLogin() {
        do {
            try SMAppService.mainApp.register()
            openAtLoginMenuItem.state = .on
            openAtLoginMenuItem.action = #selector(removeOpenAtLogin)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @objc func removeOpenAtLogin() {
        do {
            try SMAppService.mainApp.unregister()
            openAtLoginMenuItem.state = .off
            openAtLoginMenuItem.action = #selector(openAtLogin)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func menuWillOpen(_: NSMenu) {
        if SMAppService.mainApp.status == .enabled {
            openAtLoginMenuItem.state = .on
            openAtLoginMenuItem.action = #selector(removeOpenAtLogin)
        } else {
            openAtLoginMenuItem.state = .off
            openAtLoginMenuItem.action = #selector(openAtLogin)
        }
    }

    func resetTimer() {
        timerStart = Date()
        updateButton()
    }

    func onMouseEvent(_: NSEvent) {
        if let eventMonitor = mouseEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            mouseEventMonitor = nil
        }
        updateButton()
    }

    func updateButton() {
        var idle: Bool

        if sinceUserActivity() > userIdleSeconds {
            timerStart = Date()
            idle = true
        } else if CGDisplayIsAsleep(CGMainDisplayID()) == 1 {
            timerStart = Date()
            idle = true
        } else {
            idle = false
        }

        if let statusButton = statusItem.button {
            let duration = Date().timeIntervalSince(timerStart)
            let title = duration.formatted(.custom)

            statusButton.title = title
            statusButton.appearsDisabled = idle
        }

        if idle {
            // On next mouse event, immediately update button
            if mouseEventMonitor == nil {
                mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
                    NSEvent.EventTypeMask.mouseMoved,
                    NSEvent.EventTypeMask.leftMouseDown,
                ], handler: onMouseEvent)
            }
        }
    }

    let userActivityEventTypes: [CGEventType] = [
        .leftMouseDown,
        .rightMouseDown,
        .mouseMoved,
        .keyDown,
        .scrollWheel,
    ]

    func sinceUserActivity() -> CFTimeInterval {
        return userActivityEventTypes.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min()!
    }
}
