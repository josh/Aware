//
//  VisionScene.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(visionOS)

import SwiftUI

struct VisionScene: Scene {
    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        .defaultSize(CGSize(width: 200, height: 100))
        .windowResizability(.contentMinSize)
        .windowStyle(.plain)
    }
}

#endif
