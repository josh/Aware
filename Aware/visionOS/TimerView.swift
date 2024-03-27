//
//  TimerView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct TimerView: View {
    @State private var timerState = TimerState()

    @SceneStorage("glassBackground") private var glassBackground: Bool = true
    @State private var showSettings = false

    /// Set text refresh rate to 60 seconds, as only minutes are shown
    private let textRefreshRate: TimeInterval = 60.0

    var body: some View {
        Group {
            if let start = timerState.start {
                TimelineView(.periodic(from: start.date, by: textRefreshRate)) { context in
                    let duration = timerState.duration(to: UTCClock.Instant(context.date))
                    TimerTextView(duration: duration, glassBackground: glassBackground)
                }
            } else {
                TimerTextView(duration: .zero, glassBackground: glassBackground)
            }
        }
        .task {
            for await state in ActivityMonitor(initialState: timerState).updates() {
                timerState = state
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
    TimerView()
}

#endif
