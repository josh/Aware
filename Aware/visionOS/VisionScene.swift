//
//  VisionScene.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(visionOS)

import SwiftUI

struct VisionScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    @State private var startDate: Date?

    var body: some Scene {
        WindowGroup {
            TimelineView(.everyMinute) { context in
                let duration = context.date.timeIntervalSince(startDate ?? .now)
                Text(duration.formatted(.custom))
                    .lineLimit(1)
                    .padding()
                    .font(.system(size: 900))
                    .minimumScaleFactor(0.01)
            }
        }
        .defaultSize(CGSize(width: 200, height: 100))
        .windowResizability(.contentMinSize)
        .onChange(of: scenePhase, initial: true) { _, newValue in
            switch newValue {
            case .active, .inactive:
                if self.startDate == nil {
                    self.startDate = .now
                }
            case .background:
                self.startDate = nil
            default:
                ()
            }
        }
    }
}

#endif
