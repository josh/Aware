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
        #endif

        #if os(visionOS)
        WindowGroup {
            TimerView()
        }
        .defaultSize(CGSize(width: 200, height: 100))
        .windowResizability(.contentMinSize)
        .windowStyle(.plain)
        #endif
    }
}
