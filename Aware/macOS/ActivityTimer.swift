//
//  ActivityTimer.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityTimer")

/// Automatically tracks macOS user input activity.
/// Timer continues running as long as user has made an input within the `userIdleSeconds` interval.
/// Sleeping or waking the computer will reset the timer back to zero.
class ActivityTimer: ObservableObject {
    /// The number of seconds since the last user event to consider time idle.
    var userIdleSeconds: TimeInterval

    /// The poll interval for checking user activity timestamps.
    let pollInterval: TimeInterval = 60.0

    /// The allowed poll timer variance.
    let pollTolerance: TimeInterval = 5.0

    @Published var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.info("state changed from \(oldValue) to \(newValue)")
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var userActivityCancellable: AnyCancellable?

    init(userIdleSeconds: TimeInterval) {
        self.userIdleSeconds = userIdleSeconds

        Timer.publish(every: pollInterval, tolerance: pollTolerance, on: .main, in: .default)
            .autoconnect()
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.poll()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.willSleepNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("will sleep")
                self.state.deactivate()
                self.poll()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("did wake")
                self.state.activate()
                self.poll()
            }
            .store(in: &cancellables)

        poll()
    }

    var startDate: Date? {
        state.start?.date
    }

    var isIdle: Bool {
        state.isIdle
    }

    func duration(to endDate: Date) -> Duration {
        state.duration(to: .init(endDate))
    }

    private func poll() {
        let hasRecentUserEvent = secondsSinceLastUserEvent() < userIdleSeconds
        let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

        if !hasRecentUserEvent || isMainDisplayAsleep {
            state.deactivate()
            schedulePollOnNextEvent()
        } else {
            state.activate()
        }
    }

    private func schedulePollOnNextEvent() {
        guard userActivityCancellable == nil else { return }

        userActivityCancellable = NSEventGlobalPublisher(mask: userActivityEventMask)
            .map { _ in () }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                logger.info("mouse event")
                self.userActivityCancellable = nil
                self.poll()
            }
    }
}

private let userActivityEventMask: NSEvent.EventTypeMask = [
    .leftMouseDown,
    .rightMouseDown,
    .mouseMoved,
    .keyDown,
    .scrollWheel,
]

private let userActivityEventTypes: [CGEventType] = [
    .leftMouseDown,
    .rightMouseDown,
    .mouseMoved,
    .keyDown,
    .scrollWheel,
]

private func secondsSinceLastUserEvent() -> CFTimeInterval {
    return userActivityEventTypes.map { eventType in
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: eventType)
    }.min() ?? 0.0
}

#endif
