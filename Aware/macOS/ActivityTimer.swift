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
    private enum State {
        case idle
        case active(Date, TimeInterval)

        static var restart: Self { .active(.now, 0.0) }

        var extend: Self {
            switch self {
            case let .active(start, _):
                return .active(start, Date.now.timeIntervalSince(start))
            case .idle:
                return .restart
            }
        }
    }

    /// Returns a boolean value indicating whether the timer is idle.
    var idle: Bool {
        switch state {
        case .idle: return true
        case .active: return false
        }
    }

    /// The number of seconds the timer has been active. Return zero if timer is idle.
    var duration: TimeInterval {
        switch state {
        case .idle: return 0.0
        case let .active(_, duration): return duration
        }
    }

    private var state: State = .restart {
        willSet {
            objectWillChange.send()
        }
    }

    /// The number of seconds since the last user event to consider time idle.
    var userIdleSeconds: TimeInterval

    /// The poll interval for checking user activity timestamps.
    let pollInterval: TimeInterval = 60.0

    /// The allowed poll timer variance.
    let pollTolerance: TimeInterval = 5.0

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
                self.state = .idle
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
                self.state = .restart
                self.poll()
            }
            .store(in: &cancellables)

        poll()
    }

    private func poll() {
        let hasRecentUserEvent = secondsSinceLastUserEvent() < userIdleSeconds
        let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

        logger.debug("recent user event: \(hasRecentUserEvent, privacy: .public)")
        if isMainDisplayAsleep {
            logger.info("display asleep")
        }

        if !hasRecentUserEvent || isMainDisplayAsleep {
            if case .active = state {
                state = .idle
            }
            schedulePollOnNextEvent()
        } else {
            state = state.extend
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
