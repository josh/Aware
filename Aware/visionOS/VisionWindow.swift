//
//  VisionWindow.swift
//  Aware
//
//  Created by Joshua Peek on 2/23/24.
//

#if os(visionOS)

import SwiftUI

struct VisionWindow: Scene {
    @State private var protectedDataAvailablity = ProtectedDataAvailablity()

    var body: some Scene {
        WindowGroup {
            TimerView(protectedDataAvailablity: protectedDataAvailablity)
        }
        .defaultSize(width: 240, height: 135)
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        .backgroundTask(.appRefresh(ProtectedDataAvailablity.appRefreshIdentifier)) {
            await protectedDataAvailablity.appRefreshCheck()
        }
    }
}

#endif
