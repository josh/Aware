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

    @AppStorage("showSeconds") private var showSeconds: Bool = false
    @AppStorage("formatStyle") private var timerFormatStyle: TimerFormatStyle.Style = .condensedAbbreviated
    @AppStorage("glassBackground") private var glassBackground: Bool = true

    @AppStorage("backgroundTaskInterval") private var backgroundTaskInterval: Int = 300
    @AppStorage("backgroundGracePeriod") private var backgroundGracePeriod: Int = 7200
    @AppStorage("lockGracePeriod") private var lockGracePeriod: Int = 60
    @AppStorage("maxSuspendingClockDrift") private var maxSuspendingClockDrift: Int = 10

    /// Set text refresh rate to 60 seconds, when minutes are shown
    private var textRefreshRate: TimeInterval { showSeconds ? 1.0 : 60.0 }

    private var timerFormat: TimerFormatStyle {
        TimerFormatStyle(style: timerFormatStyle, includeSeconds: showSeconds)
    }

    private var activityMonitor: ActivityMonitor {
        ActivityMonitor(
            initialState: timerState,
            backgroundTaskInterval: .seconds(backgroundTaskInterval),
            backgroundGracePeriod: .seconds(backgroundGracePeriod),
            lockGracePeriod: .seconds(lockGracePeriod),
            maxSuspendingClockDrift: .seconds(maxSuspendingClockDrift)
        )
    }

    var body: some View {
        Group {
            if let start = timerState.start {
                TimelineView(.periodic(from: start.date, by: textRefreshRate)) { context in
                    let duration = timerState.duration(to: UTCClock.Instant(context.date))
                    TimerTextView(duration: duration, format: timerFormat, glassBackground: glassBackground)
                }
            } else {
                TimerTextView(duration: .zero, format: timerFormat, glassBackground: glassBackground)
            }
        }
        .task(id: activityMonitor) {
            for await state in activityMonitor.updates() {
                timerState = state
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    TimerView()
}

#endif
