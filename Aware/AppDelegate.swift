//
//  AppDelegate.swift
//  Aware
//
//  Created by Joshua Peek on 12/06/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import Cocoa

// Sandboxed ~/Library
let userLibraryPath = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0]

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var timerStart: NSDate = NSDate()

    // User activity binary log path
    let logPath = NSURL(fileURLWithPath: userLibraryPath).URLByAppendingPathComponent("Logs/Aware.log").path!

    // User activity binary log stream
    var logStream: NSOutputStream?

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // Reference to installed global mouse event monitor
    var mouseEventMonitor: AnyObject?

    // Default value to initialize userIdleSeconds to
    static let defaultUserIdleSeconds: NSTimeInterval = 120

    // User configurable idle time in seconds (defaults to 2 minutes)
    var userIdleSeconds: NSTimeInterval = defaultUserIdleSeconds

    func readUserIdleSeconds() -> NSTimeInterval {
        let defaults = NSUserDefaults.standardUserDefaults()
        let defaultsValue = defaults.objectForKey("userIdleSeconds") as? NSTimeInterval
        return defaultsValue ?? self.dynamicType.defaultUserIdleSeconds
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

    func applicationDidFinishLaunching(notification: NSNotification) {
        print("Logging user activity to \(logPath)")
        self.logStream = NSOutputStream(toFileAtPath: logPath, append: true)
        self.logStream?.open()

        self.userIdleSeconds = self.readUserIdleSeconds()

        updateButton()
        NSTimer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserverForName(NSWorkspaceWillSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserverForName(NSWorkspaceDidWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }
    }

    func applicationWillTerminate(notification: NSNotification) {
        self.logStream?.close()
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
            logUserActivity()
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

    func logUserActivity() {
        let data = NSMutableData()
        var number: Double = NSDate().timeIntervalSince1970
        data.appendBytes(&number, length: sizeof(Double))

        let bytes = UnsafePointer<UInt8>(data.bytes)
        logStream?.write(bytes, maxLength: data.length)
    }
}
