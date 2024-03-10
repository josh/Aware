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
        state = .active(start: start)
    }

    /// Initializes timer in active state until the specified expiration time.
    /// - Parameters:
    ///   - start: When the timer has started
    ///   - expires: When the timer should expire
    ///   - clock: A clock instance
    init(since start: C.Instant, until expires: C.Instant, clock: C) {
        self.clock = clock
        state = .grace(start: start, expires: expires)
    }

    /// Check if the timer is active.
    var isActive: Bool {
        switch state {
        case .idle:
            return false
        case let .grace(_, expires):
            return clock.now < expires
        case .active:
            return true
        }
    }

    /// Check if the timer is idle.
    var isIdle: Bool {
        return !isActive
    }

    /// Check timer has associated expiration, regardless of it being valid.
    var hasExpiration: Bool {
        if case .grace = state {
            return true
        } else {
            return false
        }
    }

    /// Get valid timer start instant. Return `nil` if idle or grace period has expired.
    var start: C.Instant? {
        switch state {
        case .idle:
            return nil
        case let .grace(start, expires):
            return clock.now < expires ? start : nil
        case let .active(start):
            return start
        }
    }

    /// If timer has an expiration, return the instant.
    var expires: C.Instant? {
        switch state {
        case .idle:
            return nil
        case let .grace(_, expires):
            return clock.now < expires ? expires : nil
        case .active:
            return nil
        }
    }

    /// Get duration the timer has been running for.
    /// - Parameter end: The current clock instant
    /// - Returns: the duration or zero if timer is idle
    func duration(to end: C.Instant) -> C.Duration {
        if let start {
            return start.duration(to: end)
        } else {
            return C.Duration.zero
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
}

// Unsure if Clocks should be Equatable by convention.
extension TimerState: Equatable where C: Equatable {}

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
                let expiresFormatted = now.duration(to: expires).formatted(.time(pattern: .hourMinuteSecond))
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
