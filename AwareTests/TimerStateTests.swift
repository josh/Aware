import XCTest

@testable import Aware

final class PausedClock: @unchecked Sendable, Clock, Equatable {
    var now: Instant
    init() { now = .now }

    typealias Instant = ContinuousClock.Instant
    var minimumResolution: Duration { ContinuousClock().minimumResolution }
    func sleep(until _: Instant, tolerance _: Duration?) async throws {}

    static func == (_: PausedClock, _: PausedClock) -> Bool { true }

    func advance(by duration: Duration) {
        now = now.advanced(by: duration)
    }
}

final class TimerStateTests: XCTestCase {
    let clock: PausedClock = .init()

    func testIsActive() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertFalse(timer.isActive)

        let start = clock.now.advanced(by: .seconds(-30))
        timer = TimerState(since: start, clock: clock)
        XCTAssertTrue(timer.isActive)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(150)), clock: clock)
        XCTAssertTrue(timer.isActive)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertFalse(timer.isActive)
    }

    func testIsIdle() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertTrue(timer.isIdle)

        let start = clock.now.advanced(by: .seconds(-30))
        timer = TimerState(since: start, clock: clock)
        XCTAssertFalse(timer.isIdle)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(150)), clock: clock)
        XCTAssertFalse(timer.isIdle)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertTrue(timer.isIdle)
    }

    func testStart() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertNil(timer.start)

        let start = clock.now.advanced(by: .seconds(-30))
        timer = TimerState(since: start, clock: clock)
        XCTAssertEqual(timer.start, start)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(150)), clock: clock)
        XCTAssertEqual(timer.start, start)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertNil(timer.start)
    }

    func testExpires() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertNil(timer.expires)

        let start = clock.now.advanced(by: .seconds(-30))
        timer = TimerState(since: start, clock: clock)
        XCTAssertNil(timer.expires)

        let expires = clock.now.advanced(by: .seconds(150))
        timer = TimerState(since: start, until: expires, clock: clock)
        XCTAssertEqual(timer.expires, expires)

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertNil(timer.expires)
    }

    func testDuration() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertEqual(timer.duration(to: clock.now), .seconds(0))

        let start = clock.now.advanced(by: .seconds(-30))
        timer = TimerState(since: start, clock: clock)
        XCTAssertEqual(timer.duration(to: clock.now), .seconds(30))

        let expires = clock.now.advanced(by: .seconds(150))
        timer = TimerState(since: start, until: expires, clock: clock)
        XCTAssertEqual(timer.duration(to: clock.now), .seconds(30))

        timer = TimerState(since: start, until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertEqual(timer.duration(to: clock.now), .seconds(0))
    }

    func testDeactivate() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        timer.deactivate()
        XCTAssertEqual(String(describing: timer), "idle")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), clock: clock)
        timer.deactivate()
        XCTAssertEqual(String(describing: timer), "idle")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        timer.deactivate()
        XCTAssertEqual(String(describing: timer), "idle")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        timer.deactivate()
        XCTAssertEqual(String(describing: timer), "idle")
    }

    func testActivate() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        timer.activate()
        XCTAssertEqual(String(describing: timer), "active[0:00:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), clock: clock)
        timer.activate()
        XCTAssertEqual(String(describing: timer), "active[0:05:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        timer.activate()
        XCTAssertEqual(String(describing: timer), "active[0:05:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        timer.activate()
        XCTAssertEqual(String(describing: timer), "active[0:00:00]")
    }

    func testActivateUntil() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        timer.activate(until: clock.now.advanced(by: .seconds(60)))
        XCTAssertEqual(String(describing: timer), "active[0:00:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), clock: clock)
        timer.activate(until: clock.now.advanced(by: .seconds(60)))
        XCTAssertEqual(String(describing: timer), "active[0:05:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        timer.activate(until: clock.now.advanced(by: .seconds(60)))
        XCTAssertEqual(String(describing: timer), "active[0:05:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        timer.activate(until: clock.now.advanced(by: .seconds(60)))
        XCTAssertEqual(String(describing: timer), "active[0:00:00, expires in 0:01:00]")
    }

    func testActivateFor() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        timer.activate(for: .seconds(60))
        XCTAssertEqual(String(describing: timer), "active[0:00:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), clock: clock)
        timer.activate(for: .seconds(60))
        XCTAssertEqual(String(describing: timer), "active[0:05:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        timer.activate(for: .seconds(60))
        XCTAssertEqual(String(describing: timer), "active[0:05:00, expires in 0:01:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        timer.activate(for: .seconds(60))
        XCTAssertEqual(String(describing: timer), "active[0:00:00, expires in 0:01:00]")
    }

    func testEquatable() {
        XCTAssertEqual(TimerState(clock: clock), TimerState(clock: clock))
        XCTAssertEqual(TimerState(since: clock.now, clock: clock), TimerState(since: clock.now, clock: clock))
        XCTAssertNotEqual(TimerState(since: clock.now, clock: clock), TimerState(clock: clock))
        XCTAssertNotEqual(TimerState(clock: clock), TimerState(since: clock.now.advanced(by: .seconds(-1)), clock: clock))
    }

    func testCustomStringConvertible() {
        var timer: TimerState<PausedClock>

        timer = TimerState(clock: clock)
        XCTAssertEqual(String(describing: timer), "idle")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-5)), clock: clock)
        XCTAssertEqual(String(describing: timer), "active[0:00:05]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), clock: clock)
        XCTAssertEqual(String(describing: timer), "active[0:05:00]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(150)), clock: clock)
        XCTAssertEqual(String(describing: timer), "active[0:05:00, expires in 0:02:30]")

        timer = TimerState(since: clock.now.advanced(by: .seconds(-300)), until: clock.now.advanced(by: .seconds(30)), clock: clock)
        clock.advance(by: .seconds(60))
        XCTAssertEqual(String(describing: timer), "idle[expired]")
    }
}
