//
//  AppDelegate.swift
//  Aware
//
//  Created by Joshua Peek on 12/06/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import AppKit
import Combine
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    // Redraw button every minute
    let buttonRefreshRate: TimeInterval = 60

    // User configurable idle time in seconds (defaults to 2 minutes)
    @AppStorage("userIdleSeconds") private var userIdleSeconds: TimeInterval = 120.0

    private var activityTimer: ActivityTimer?
    private var activityTimerCancellable: AnyCancellable?

    private lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        return statusItem
    }()

    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(openAtLoginMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        menu.delegate = self
        return menu
    }()

    private let openAtLoginMenuItem = NSMenuItem(
        title: "Open at Login",
        action: #selector(openAtLogin),
        keyEquivalent: ""
    )

    private let quitMenuItem = NSMenuItem(
        title: "Quit Aware",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
    )

    func applicationDidFinishLaunching(_: Notification) {
        let activityTimer = ActivityTimer(userIdleSeconds: userIdleSeconds, pollInterval: buttonRefreshRate)
        self.activityTimer = activityTimer

        updateStatusButton()
        activityTimerCancellable = activityTimer.objectWillChange.sink { _ in
            self.updateStatusButton()
        }
    }

    private func updateStatusButton() {
        guard let statusButton = statusItem.button else { return }
        guard let activityTimer = activityTimer else { return }
        statusButton.title = activityTimer.duration.formatted(.custom)
        statusButton.appearsDisabled = activityTimer.idle
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
}
