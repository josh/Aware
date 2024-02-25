//
//  TimerView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct TimerView: View {
    @SceneStorage("glassBackground") private var glassBackground: Bool = true
    @State private var activityTimer = ActivityTimer.shared
    @State private var showSettings = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            let duration = activityTimer.timeIntervalFrom(context.date)
            TimerTextView(duration: duration, glassBackground: glassBackground)
            #if DEBUG
                .onLongPressGesture {
                    showSettings.toggle()
                }
            #endif
        }
        #if DEBUG
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
