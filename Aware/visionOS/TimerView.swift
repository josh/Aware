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
    @Environment(\.scenePhase) private var scenePhase
    @State private var protectedDataAvailablity = ProtectedDataAvailablity()
    @State private var startDate: Date?
    @State private var showSettings = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            let duration = context.date.timeIntervalSince(startDate ?? .now)
            TimerTextView(duration: duration, glassBackground: glassBackground)
                .onLongPressGesture {
                    showSettings.toggle()
                }
        }
        .popover(isPresented: $showSettings) {
            SettingsView(glassBackground: $glassBackground)
                .frame(width: 400, height: 250)
        }
        .onChange(of: scenePhase, initial: true) { _, newValue in
            switch newValue {
            case .active, .inactive:
                if self.startDate == nil {
                    print("scenePhase change started timer")
                    self.startDate = .now
                }
            case .background:
                ()
            default:
                ()
            }
        }
        .onChange(of: protectedDataAvailablity.isAvailable) { oldValue, newValue in
            if oldValue == false && newValue == true {
                if self.startDate == nil {
                    print("protectedDataAvailablity change started timer")
                    self.startDate = .now
                }
            } else if oldValue == true && newValue == false {
                print("protectedDataAvailablity stopped timer")
                self.startDate = nil
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    TimerView()
}

#endif
