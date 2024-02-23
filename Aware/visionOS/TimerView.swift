//
//  TimerView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import BackgroundTasks
import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "TimerView")

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
    private var protectedDataAvailablity: ProtectedDataAvailablity
    @State private var state: TimerState = .idle
    @State private var showSettings = false

    init(protectedDataAvailablity: ProtectedDataAvailablity) {
        self.protectedDataAvailablity = protectedDataAvailablity
    }

    init() {
        protectedDataAvailablity = .init()
    }

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
                if case .idle = state {
                    logger.info("Foreground, starting timer")
                }
                state = state.running

                if state.timeIntervalFrom(.now) > TimerState.maxTimeInterval {
                    logger.error("Timer duration extended max value")
                    state = .restart
                }

                protectedDataAvailablity.cancelBackgroundTasks()

            case .background:
                logger.info("Background, scheduled background task")
                if !protectedDataAvailablity.scheduleBackgroundCheck() {
                    logger.warning("Couldn't schedule background task, idle")
                    state = .idle
                }

            default:
                ()
            }
        }
        .onChange(of: protectedDataAvailablity.isAvailable) { oldValue, newValue in
            if oldValue == false && newValue == true {
                logger.debug("Device unlocked, continue running timer")
                state = state.running
            } else if oldValue == true && newValue == false {
                logger.info("Device locked, idle timer")
                state = .idle
                protectedDataAvailablity.cancelBackgroundTasks()
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 200, height: 100)) {
    TimerView()
}

#endif
