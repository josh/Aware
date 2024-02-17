//
//  ActivityTimer.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

import AppKit

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

    private var state: State = .restart

    let userIdleSeconds: TimeInterval
    let pollInterval: TimeInterval

    private var timer: Timer?
    private var willSleepObserver: NSObjectProtocol?
    private var didWakeObserver: NSObjectProtocol?
    private var mouseEventMonitor: Any?

    init(userIdleSeconds: TimeInterval, pollInterval: TimeInterval) {
        self.userIdleSeconds = userIdleSeconds
        self.pollInterval = pollInterval

        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            self.poll()
        }

        let notificationCenter = NSWorkspace.shared.notificationCenter
        willSleepObserver = notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            self.state = .idle
            self.poll()
        }
        didWakeObserver = notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            self.state = .restart
            self.poll()
        }

        DispatchQueue.main.async {
            self.poll()
        }
    }

    deinit {
        assert(Thread.isMainThread)

        timer?.invalidate()
        self.timer = nil

        let notificationCenter = NSWorkspace.shared.notificationCenter
        if let willSleepObserver {
            notificationCenter.removeObserver(willSleepObserver)
        }
        self.willSleepObserver = nil

        if let didWakeObserver {
            notificationCenter.removeObserver(didWakeObserver)
        }
        self.didWakeObserver = nil

        if let mouseEventMonitor {
            NSEvent.removeMonitor(mouseEventMonitor)
        }
        self.mouseEventMonitor = nil
    }

    private func poll() {
        let hasRecentUserEvent = secondsSinceLastUserEvent() > userIdleSeconds
        let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

        if hasRecentUserEvent || isMainDisplayAsleep {
            if case .active = state {
                state = .idle
                objectWillChange.send()
            }
            schedulePollOnNextMouseEvent()
        } else {
            state = state.extend
            objectWillChange.send()
        }
    }

    private func schedulePollOnNextMouseEvent() {
        guard mouseEventMonitor == nil else { return }

        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEventMask) { [weak self] _ in
            assert(self != nil)
            assert(Thread.isMainThread)
            guard let self = self else { return }
            if let mouseEventMonitor = self.mouseEventMonitor {
                NSEvent.removeMonitor(mouseEventMonitor)
                self.mouseEventMonitor = nil
            }
            self.poll()
        }
    }
}

private let mouseEventMask: NSEvent.EventTypeMask = [
    .mouseMoved,
    .leftMouseDown,
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
