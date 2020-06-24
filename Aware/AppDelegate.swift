//
//  AppDelegate.swift
//  Aware
//
//  Created by Joshua Peek on 12/06/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var timerStart: Date = Date()

    // Redraw button every minute
    let buttonRefreshRate: TimeInterval = 60

    // Reference to installed global mouse event monitor
    var mouseEventMonitor: Any?

    // Default value to initialize userIdleSeconds to
    static let defaultUserIdleSeconds: TimeInterval = 120

    // User configurable idle time in seconds (defaults to 2 minutes)
    var userIdleSeconds: TimeInterval = defaultUserIdleSeconds

    func readUserIdleSeconds() -> TimeInterval {
        let defaultsValue = UserDefaults.standard.object(forKey: "userIdleSeconds") as? TimeInterval
        return defaultsValue ?? type(of: self).defaultUserIdleSeconds
    }

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var menu: NSMenu! {
        didSet {
            statusItem.menu = menu
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.userIdleSeconds = self.readUserIdleSeconds()

        updateButton()
        let _ = Timer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }
    }

    func resetTimer() {
        timerStart = Date()
        updateButton()
    }

    func onMouseEvent(_ event: NSEvent) {
        if let eventMonitor = mouseEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            mouseEventMonitor = nil
        }
        updateButton()
    }

    func updateButton() {
        var idle: Bool

        if (self.sinceUserActivity() > userIdleSeconds) {
            timerStart = Date()
            idle = true
        } else if (CGDisplayIsAsleep(CGMainDisplayID()) == 1) {
            timerStart = Date()
            idle = true
        } else {
            idle = false
        }

        let duration = Date().timeIntervalSince(timerStart)
        let title = NSTimeIntervalFormatter().stringFromTimeInterval(duration)
        statusItem.button!.title = title

        if (idle) {
            statusItem.button!.attributedTitle = updateAttributedString(statusItem.button!.attributedTitle, [
                NSAttributedString.Key.foregroundColor: NSColor.controlTextColor.withAlphaComponent(0.1)
            ])

            // On next mouse event, immediately update button
            if mouseEventMonitor == nil {
                mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
                    NSEvent.EventTypeMask.mouseMoved,
                    NSEvent.EventTypeMask.leftMouseDown
                ], handler: onMouseEvent)
            }
        }
    }

    let userActivityEventTypes: [CGEventType] = [
        .leftMouseDown,
        .rightMouseDown,
        .mouseMoved,
        .keyDown,
        .scrollWheel
    ]

    func sinceUserActivity() -> CFTimeInterval {
        return userActivityEventTypes.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min()!
    }

    func updateAttributedString(_ attributedString: NSAttributedString, _ attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let str = NSMutableAttributedString(attributedString: attributedString)
        str.addAttributes(attributes, range: NSMakeRange(0, str.length))
        return str
    }
}
