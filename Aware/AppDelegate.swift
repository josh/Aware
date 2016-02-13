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
    var timerStart: NSDate = NSDate()

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // Reference to installed global mouse event monitor
    var mouseEventMonitor: AnyObject?

    // User configurable idle time in seconds (defaults to 2 minutes)
    var userIdleSeconds: NSTimeInterval = 120 {
        didSet {
            userIdleSecondsMenu.setTimeInterval(userIdleSeconds)
        }
    }

    func readUserIdleSeconds() -> NSTimeInterval {
        let defaults = NSUserDefaults.standardUserDefaults()
        let defaultsValue = defaults.objectForKey("userIdleSeconds") as? NSTimeInterval
        return defaultsValue ?? 120
    }

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    @IBOutlet weak var menu: NSMenu! {
        didSet {
            statusItem.menu = menu
        }
    }

    @IBOutlet weak var userIdleSecondsMenu: TimeIntervalMenu!

    func applicationDidFinishLaunching(notification: NSNotification) {
        updateButton()
        self.userIdleSeconds = self.readUserIdleSeconds()

        NSTimer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserverForName(NSWorkspaceWillSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserverForName(NSWorkspaceDidWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }
    }

    func resetTimer() {
        timerStart = NSDate()
        updateButton()
    }

    func onMouseEvent(event: NSEvent) {
        if let eventMonitor = mouseEventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            mouseEventMonitor = nil
        }
        updateButton()
    }

    func updateButton() {
        var idle: Bool

        let sinceUserActivity = CGEventSourceSecondsSinceLastEventType(.CombinedSessionState, AnyInputEventType)
        if (sinceUserActivity > userIdleSeconds) {
            timerStart = NSDate()
            idle = true
        } else if (CGDisplayIsAsleep(CGMainDisplayID()) == 1) {
            timerStart = NSDate()
            idle = true
        } else {
            idle = false
        }

        let duration = NSDate().timeIntervalSinceDate(timerStart)
        let title = NSTimeIntervalFormatter().stringFromTimeInterval(duration)
        statusItem.button!.title = title

        if (idle) {
            statusItem.button!.attributedTitle = updateAttributedString(statusItem.button!.attributedTitle, [
                NSForegroundColorAttributeName: NSColor.controlTextColor().colorWithAlphaComponent(0.1)
            ])

            // On next mouse event, immediately update button
            if mouseEventMonitor == nil {
                mouseEventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask([.MouseMovedMask, .LeftMouseDownMask], handler: onMouseEvent)
            }
        }
    }

    func updateAttributedString(attributedString: NSAttributedString, _ attributes: [String: AnyObject]) -> NSAttributedString {
        let str = NSMutableAttributedString(attributedString: attributedString)
        str.addAttributes(attributes, range: NSMakeRange(0, str.length))
        return str
    }

    @IBAction func setUserIdleSecondsFromMenuItem(menuItem: TimeIntervalMenuItem) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(menuItem.value, forKey: "userIdleSeconds")

        // Recompute userIdleSeconds property
        userIdleSeconds = self.readUserIdleSeconds()
    }
}
