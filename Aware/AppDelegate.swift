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
    let appURL: NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath)

    var timerStart: NSDate = NSDate()

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // User configurable idle time in seconds (defaults to 2 minutes)
    //
    //   defaults write com.github.josh.Aware userIdleSeconds -int 120
    lazy var userIdleSeconds: NSTimeInterval = self.readUserIdleSeconds()
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

    func applicationDidFinishLaunching(notification: NSNotification) {
        updateButton()
        NSTimer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserverForName(NSWorkspaceWillSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserverForName(NSWorkspaceDidWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }

        if SessionLoginItems.findURL(appURL) != nil {
            startAtLoginMenuItem.state = 1
        }
    }

    func resetTimer() {
        timerStart = NSDate()
        self.updateButton()
    }

    func updateButton() {
        let sinceUserActivity = CGEventSourceSecondsSinceLastEventType(.CombinedSessionState, AnyInputEventType)
        if (sinceUserActivity > userIdleSeconds) {
            timerStart = NSDate()
        }

        let duration = NSDate().timeIntervalSinceDate(timerStart)
        statusItem.button!.title = NSTimeIntervalFormatter().stringFromTimeInterval(duration)
    }

    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!

    @IBAction func toggleStartAtLogin(menuItem: NSMenuItem) {
        if menuItem.state == 1 {
            SessionLoginItems.removeURL(appURL)
            menuItem.state = 0
        } else {
            SessionLoginItems.addURL(appURL)
            menuItem.state = 1
        }
    }
}
