//
//  TimerView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct TimerView: View {
    var activityMonitor: ActivityMonitor

    @SceneStorage("glassBackground") private var glassBackground: Bool = true
    @State private var showSettings = false

    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    var body: some View {
        Group {
            if let startDate = self.activityMonitor.startDate {
                TimelineView(.periodic(from: startDate, by: textRefreshRate)) { context in
                    let duration = activityMonitor.duration(to: context.date)
                    TimerTextView(duration: duration, glassBackground: glassBackground)
                }
            } else {
                TimerTextView(duration: .zero, glassBackground: glassBackground)
            }
        }
        #if DEBUG
        .onLongPressGesture {
                showSettings.toggle()
            }
            .popover(isPresented: $showSettings) {
                SettingsView(glassBackground: $glassBackground)
                    .frame(width: 400, height: 250)
            }
        #endif
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    TimerView(activityMonitor: .init())
}

#endif
