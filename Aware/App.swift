//
//  App.swift
//  Aware
//
//  Created by Joshua Peek on 2/12/24.
//

import SwiftUI

@main
struct AwareApp: App {
    var body: some Scene {
        #if os(macOS)
        MenuBar()
        Settings {
            SettingsView()
        }
        #endif

        #if os(visionOS)
        TimerWindow()
        #endif
    }
}
