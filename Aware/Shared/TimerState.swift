//
//  TimerState.swift
//  Aware
//
//  Created by Joshua Peek on 3/9/24.
//

import Foundation

struct TimerState<C: Clock>: Sendable {
    let clock: C

    private var state: InternalState

    private enum InternalState: Hashable, Sendable {
        case idle
        case grace(start: C.Instant, expires: C.Instant)
        case active(start: C.Instant)
    }

    /// Initializes timer in idle state.
    /// - Parameter clock: A clock instance
    init(clock: C) {
        self.clock = clock
        state = .idle
    }

    /// Initializes timer in active state since the specified start time.
    /// - Parameters:
    ///   - start: When the timer has started
    ///   - clock: A clock instance
    init(since start: C.Instant, clock: C) {
        self.clock = clock
        assert(start <= clock.now, "start should be now or in the past")
        state = .active(start: start)
    }

    /// Initializes timer in active state until the specified expiration time.
    /// - Parameters:
    ///   - start: When the timer has started
    ///   - expires: When the timer should expire
    ///   - clock: A clock instance
    init(since start: C.Instant, until expires: C.Instant, clock: C) {
        self.clock = clock
        assert(start <= clock.now, "start should be now or in the past")
        assert(expires > clock.now, "expires should be in the future")
        state = .grace(start: start, expires: expires)
    }

    /// Check if the timer is active.
    var isActive: Bool {
        switch state {
        case .idle:
            false
        case let .grace(_, expires):
            clock.now < expires
        case .active:
            true
        }
    }

    /// Check if the timer is idle.
    var isIdle: Bool {
        !isActive
    }

    /// Check timer has associated expiration, regardless of it being valid.
    var hasExpiration: Bool {
        if case .grace = state {
            true
        } else {
            false
        }
    }

    /// Get valid timer start instant. Return `nil` if idle or grace period has expired.
    var start: C.Instant? {
        switch state {
        case .idle:
            nil
        case let .grace(start, expires):
            clock.now < expires ? start : nil
        case let .active(start):
            start
        }
    }

    /// If timer has an expiration, return the instant.
    var expires: C.Instant? {
        switch state {
        case .idle:
            nil
        case let .grace(_, expires):
            clock.now < expires ? expires : nil
        case .active:
            nil
        }
    }

    /// Get duration the timer has been running for.
    /// - Parameter end: The current clock instant
    /// - Returns: the duration or zero if timer is idle
    func duration(to end: C.Instant) -> C.Duration {
        if let start {
            start.duration(to: end)
        } else {
            C.Duration.zero
        }
    }

    /// Regardless of state, deactivate the timer putting it in idle mode.
    mutating func deactivate() {
        state = .idle
    }

    /// Activate the timer if it's idle or expired. Otherwise, perserve the current start instant.
    mutating func activate() {
        switch state {
        case .idle:
            state = .active(start: clock.now)
        case let .grace(start, expires):
            let now = clock.now
            state = .active(start: now < expires ? start : now)
        case .active:
            ()
        }
    }

    /// Activates the timer state until the specified expiration time.
    ///
    /// - Parameters:
    ///   - expires: The instant at which the timer state should expire.
    ///
    mutating func activate(until expires: C.Instant) {
        assert(expires > clock.now, "expires should be in the future")
        let now = clock.now
        switch state {
        case .idle:
            state = .grace(start: now, expires: expires)
        case let .grace(start, oldExpires):
            state = .grace(start: now < oldExpires ? start : now, expires: expires)
        case let .active(start):
            state = .grace(start: start, expires: expires)
        }
    }

    /// Activates the timer state for the specified duration.
    ///
    /// - Parameters:
    ///   - duration: The duration for which the timer state should be active.
    ///
    mutating func activate(for duration: C.Duration) {
        assert(duration > .zero, "duration should be positive")
        activate(until: clock.now.advanced(by: duration))
    }

    /// Activates the timer state setting the start to now regardless of the current state.
    mutating func restart() {
        state = .active(start: clock.now)
    }
}

extension TimerState: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state
    }
}

extension TimerState: CustomStringConvertible where C.Duration == Swift.Duration {
    /// A textual representation of this timer state.
    var description: String {
        switch state {
        case .idle:
            return "idle"

        case let .grace(start, expires):
            let now = clock.now
            if now < expires {
                let startFormatted = start.duration(to: now).formatted(.time(pattern: .hourMinuteSecond))
                let expiresFormatted = now.duration(to: expires).formatted(
                    .time(pattern: .hourMinuteSecond))
                return "active[\(startFormatted), expires in \(expiresFormatted)]"
            } else {
                return "idle[expired]"
            }

        case let .active(start):
            let now = clock.now
            let startFormatted = start.duration(to: now).formatted(.time(pattern: .hourMinuteSecond))
            return "active[\(startFormatted)]"
        }
    }
}

extension TimerState where C == UTCClock {
    init() {
        self.init(clock: UTCClock())
    }
}
