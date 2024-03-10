//
//  TimerWindow.swift
//  Aware
//
//  Created by Joshua Peek on 3/9/24.
//

#if os(visionOS)

import SwiftUI

struct TimerWindow: Scene {
    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        .defaultSize(width: 240, height: 135)
        .windowResizability(.contentSize)
        .windowStyle(.plain)
    }
}

#endif
