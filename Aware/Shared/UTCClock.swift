//
//  UTCClock.swift
//  Aware
//
//  Created by Joshua Peek on 3/8/24.
//

import Foundation

// Backport proposed Foundation UTCClock
// https://github.com/apple/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md#clocks-outside-of-the-standard-library
struct UTCClock: Clock {
    struct Instance: InstantProtocol {
        let date: Date

        init(_ date: Date) {
            self.date = date
        }

        static var now: Self { .init(.now) }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.date < rhs.date
        }

        func advanced(by duration: Duration) -> Self {
            Self(date.addingTimeInterval(duration.timeInterval))
        }

        func duration(to other: Self) -> Duration {
            Duration(timeInterval: other.date.timeIntervalSince(date))
        }
    }

    let minimumResolution: Duration = .nanoseconds(100)
    var now: Instance { .now }

    func sleep(for duration: Duration, tolerance: Duration? = nil) async throws {
        try await ContinuousClock().sleep(for: duration, tolerance: tolerance)
    }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        try await sleep(for: now.duration(to: deadline), tolerance: tolerance)
    }
}

// extension Date: InstantProtocol {
//    public func advanced(by duration: Duration) -> Date {
//        addingTimeInterval(duration.timeInterval)
//    }
//
//    public func duration(to other: Date) -> Duration {
//        Duration(timeInterval: other.timeIntervalSince(self))
//    }
// }

extension Duration {
    init(timeInterval: TimeInterval) {
        let seconds = Int64(timeInterval)
        let attoseconds = Int64((timeInterval - TimeInterval(seconds)) * 1_000_000_000_000_000_000)
        self.init(secondsComponent: seconds, attosecondsComponent: attoseconds)
    }

    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + (TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000)
    }
}
