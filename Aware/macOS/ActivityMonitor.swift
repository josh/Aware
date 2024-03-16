//
//  ActivityMonitor.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(macOS)

import AppKit
import Combine
import OSLog

private let logger = Logger(subsystem: "com.awaremac.Aware", category: "ActivityMonitor")

/// Automatically tracks macOS user input activity.
/// Timer continues running as long as user has made an input within the `userIdleSeconds` interval.
/// Sleeping or waking the computer will reset the timer back to zero.
@MainActor
class ActivityMonitor: ObservableObject {
    /// The number of seconds since the last user event to consider time idle.
    var userIdle: Duration

    @Published var state: TimerState<UTCClock> = TimerState(clock: UTCClock()) {
        didSet {
            let newValue = state
            logger.notice("State changed from \(oldValue, privacy: .public) to \(newValue, privacy: .public)")
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var updateCancellable: AnyCancellable?

    init(userIdleSeconds: TimeInterval) {
        userIdle = Duration(timeInterval: userIdleSeconds)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.willSleepNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.notice("Received willSleepNotification")
                guard let self = self else { return }
                self.state.deactivate()
                self.update()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                logger.notice("Received didWakeNotification")
                guard let self = self else { return }
                self.state.activate()
                self.update()
            }
            .store(in: &cancellables)

        update()
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

    private func update() {
        var logState = state
        logger.debug("Updating ActivityMonitor state: \(logState, privacy: .public)")

        let lastUserEvent = secondsSinceLastUserEvent()
        let idleDeadline = userIdle - lastUserEvent
        let isMainDisplayAsleep = CGDisplayIsAsleep(CGMainDisplayID()) == 1

        logger.debug("Last user event \(lastUserEvent, privacy: .public) ago")
        if isMainDisplayAsleep {
            logger.info("Main display is asleep")
        }

        updateCancellable?.cancel()

        if idleDeadline <= .zero || isMainDisplayAsleep {
            if state.isActive {
                state.deactivate()
            }
            assert(state.isIdle)

            logger.info("Scheduled next update on user event")
            updateCancellable = NSEventGlobalPublisher(mask: userActivityEventMask)
                .map { _ in () }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    logger.notice("Received user activity event")
                    self?.update()
                }
        } else {
            if state.isIdle {
                state.activate()
            }
            assert(state.isActive)

            updateCancellable = Timer.publish(every: idleDeadline.timeInterval, on: .main, in: .common)
                .autoconnect()
                .map { _ in () }
                .first()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    logger.notice("Received timer event")
                    self?.update()
                }
            logger.info("Scheduled next update in \(idleDeadline, privacy: .public)")
        }

        assert(updateCancellable != nil, "expected update to be scheduled")
        logState = state
        logger.debug("Finished updating ActivityMonitor state: \(logState, privacy: .public)")
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
