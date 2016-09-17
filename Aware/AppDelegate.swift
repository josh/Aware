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

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    @IBOutlet weak var menu: NSMenu! {
        didSet {
            statusItem.menu = menu
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.userIdleSeconds = self.readUserIdleSeconds()

        updateButton()
        let _ = Timer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.shared().notificationCenter
        notificationCenter.addObserver(forName: NSNotification.Name.NSWorkspaceWillSleep, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserver(forName: NSNotification.Name.NSWorkspaceDidWake, object: nil, queue: nil) { _ in self.resetTimer() }
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

        let sinceUserActivity = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: AnyInputEventType)
        if (sinceUserActivity > userIdleSeconds) {
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
                NSForegroundColorAttributeName: NSColor.controlTextColor.withAlphaComponent(0.1)
            ])

            // On next mouse event, immediately update button
            if mouseEventMonitor == nil {
                mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown], handler: onMouseEvent)
            }
        }
    }

    func updateAttributedString(_ attributedString: NSAttributedString, _ attributes: [String: AnyObject]) -> NSAttributedString {
        let str = NSMutableAttributedString(attributedString: attributedString)
        str.addAttributes(attributes, range: NSMakeRange(0, str.length))
        return str
    }
}
