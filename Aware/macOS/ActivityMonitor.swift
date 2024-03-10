//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityMonitor")

/// Automatically tracks macOS user input activity.
/// Timer continues running as long as user has made an input within the `userIdleSeconds` interval.
/// Sleeping or waking the computer will reset the timer back to zero.
class ActivityMonitor: ObservableObject {
    /// The number of seconds since the last user event to consider time idle.
    var userIdle: Duration

    @Published var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.info("state changed from \(oldValue) to \(newValue)")
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var pollCancellable: AnyCancellable?

    init(userIdleSeconds: TimeInterval) {
        userIdle = Duration(timeInterval: userIdleSeconds)

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
        let idleDeadline = userIdle - secondsSinceLastUserEvent()
        let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

        pollCancellable?.cancel()

        if idleDeadline <= .zero || isMainDisplayAsleep {
            if state.isActive {
                state.deactivate()
            }
            assert(state.isIdle)

            pollCancellable = NSEventGlobalPublisher(mask: userActivityEventMask)
                .map { _ in () }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.poll()
                }
        } else {
            if state.isIdle {
                state.activate()
            }
            assert(state.isActive)

            pollCancellable = Timer.publish(every: idleDeadline.timeInterval, on: .main, in: .common)
                .autoconnect()
                .map { _ in () }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.poll()
                }
        }

        assert(pollCancellable != nil, "expected poll to be scheduled")
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

private func secondsSinceLastUserEvent() -> Duration {
    return userActivityEventTypes.map { eventType in
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: eventType)
    }.min().map { ti in Duration(timeInterval: ti) } ?? .zero
}

#endif
