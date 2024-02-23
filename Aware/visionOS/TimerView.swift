//
//  TimerView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct TimerView: View {
    private enum TimerState {
        case idle
        case active(Date)

        static var restart: Self { .active(.now) }

        var running: Self {
            switch self {
            case .idle: return .active(.now)
            default: return self
            }
        }

        /// Prevent the timer from running past 24 hours.
        /// I doubt people can wear this thing for that many hours straight.
        /// It's probably a bug that the timer is still going.
        static let maxTimeInterval: TimeInterval = 24 * 60 * 60

        func timeIntervalFrom(_ endDate: Date) -> TimeInterval {
            switch self {
            case .idle: return 0.0
            case let .active(startDate): return endDate.timeIntervalSince(startDate)
            }
        }
    }

    @SceneStorage("glassBackground") private var glassBackground: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var protectedDataAvailablity = ProtectedDataAvailablity()
    @State private var state: TimerState = .idle
    @State private var showSettings = false

    var body: some View {
        TimelineView(.everyMinute) { context in
            let duration = state.timeIntervalFrom(context.date)
            TimerTextView(duration: duration, glassBackground: glassBackground)
//                 .onLongPressGesture {
//                    showSettings.toggle()
//                }
        }
//        .popover(isPresented: $showSettings) {
//            SettingsView(glassBackground: $glassBackground)
//                .frame(width: 400, height: 250)
//        }
        .onChange(of: scenePhase, initial: true) { _, newValue in
            switch newValue {
            case .active, .inactive:
                state = state.running

                if state.timeIntervalFrom(.now) > TimerState.maxTimeInterval {
                    state = .restart
                }
            case .background:
                ()
            default:
                ()
            }
        }
        .onChange(of: protectedDataAvailablity.isAvailable) { oldValue, newValue in
            if oldValue == false && newValue == true {
                state = state.running
            } else if oldValue == true && newValue == false {
                state = .idle
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    TimerView()
}

#endif
