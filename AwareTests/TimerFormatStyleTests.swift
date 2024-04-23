import XCTest

@testable import Aware

final class TimerFormatStyleTests: XCTestCase {
    func testAbbreviatedWithoutSeconds() {
        let format = TimerFormatStyle(style: .abbreviated, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "0 min")

        XCTAssertEqual(format.format(.seconds(1)), "0 min")
        XCTAssertEqual(format.format(.seconds(59)), "0 min")
        XCTAssertEqual(format.format(.minutes(1)), "1 min")
        XCTAssertEqual(format.format(.seconds(119)), "1 min")
        XCTAssertEqual(format.format(.seconds(61)), "1 min")
        XCTAssertEqual(format.format(.minutes(15)), "15 min")
        XCTAssertEqual(format.format(.minutes(59)), "59 min")
        XCTAssertEqual(format.format(.seconds(3599)), "59 min")

        XCTAssertEqual(format.format(.hours(1)), "1 hr")
        XCTAssertEqual(format.format(.seconds(3661)), "1 hr, 1 min")
        XCTAssertEqual(format.format(.seconds(4500)), "1 hr, 15 min")
        XCTAssertEqual(format.format(.seconds(7200)), "2 hr")

        XCTAssertEqual(format.format(.seconds(-1)), "0 min")
        XCTAssertEqual(format.format(.seconds(-90)), "0 min")
        XCTAssertEqual(format.format(.hours(-1)), "0 min")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0 min")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0 min")
    }

    func testAbbreviatedWithSeconds() {
        let format = TimerFormatStyle(style: .abbreviated, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "0 sec")

        XCTAssertEqual(format.format(.seconds(1)), "1 sec")
        XCTAssertEqual(format.format(.seconds(59)), "59 sec")

        XCTAssertEqual(format.format(.minutes(1)), "1 min")
        XCTAssertEqual(format.format(.seconds(119)), "1 min, 59 sec")
        XCTAssertEqual(format.format(.seconds(61)), "1 min, 1 sec")
        XCTAssertEqual(format.format(.minutes(15)), "15 min")
        XCTAssertEqual(format.format(.minutes(59)), "59 min")
        XCTAssertEqual(format.format(.seconds(3599)), "59 min, 59 sec")

        XCTAssertEqual(format.format(.hours(1)), "1 hr")
        XCTAssertEqual(format.format(.seconds(3661)), "1 hr, 1 min, 1 sec")
        XCTAssertEqual(format.format(.seconds(4500)), "1 hr, 15 min")
        XCTAssertEqual(format.format(.seconds(7200)), "2 hr")

        XCTAssertEqual(format.format(.seconds(-1)), "0 sec")
        XCTAssertEqual(format.format(.seconds(-90)), "0 sec")
        XCTAssertEqual(format.format(.hours(-1)), "0 sec")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0 sec")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0 sec")
    }

    func testCondensedAbbreviatedWithoutSeconds() {
        let format = TimerFormatStyle(style: .condensedAbbreviated, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "0m")

        XCTAssertEqual(format.format(.seconds(1)), "0m")
        XCTAssertEqual(format.format(.seconds(59)), "0m")
        XCTAssertEqual(format.format(.minutes(1)), "1m")
        XCTAssertEqual(format.format(.seconds(119)), "1m")
        XCTAssertEqual(format.format(.seconds(61)), "1m")
        XCTAssertEqual(format.format(.minutes(15)), "15m")
        XCTAssertEqual(format.format(.minutes(59)), "59m")
        XCTAssertEqual(format.format(.seconds(3599)), "59m")

        XCTAssertEqual(format.format(.hours(1)), "1h")
        XCTAssertEqual(format.format(.seconds(3661)), "1h 1m")
        XCTAssertEqual(format.format(.seconds(4500)), "1h 15m")
        XCTAssertEqual(format.format(.seconds(7200)), "2h")

        XCTAssertEqual(format.format(.seconds(-1)), "0m")
        XCTAssertEqual(format.format(.seconds(-90)), "0m")
        XCTAssertEqual(format.format(.hours(-1)), "0m")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0m")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0m")
    }

    func testCondensedAbbreviatedWithSeconds() {
        let format = TimerFormatStyle(style: .condensedAbbreviated, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "0s")

        XCTAssertEqual(format.format(.seconds(1)), "1s")
        XCTAssertEqual(format.format(.seconds(59)), "59s")

        XCTAssertEqual(format.format(.minutes(1)), "1m")
        XCTAssertEqual(format.format(.seconds(119)), "1m 59s")
        XCTAssertEqual(format.format(.seconds(61)), "1m 1s")
        XCTAssertEqual(format.format(.minutes(15)), "15m")
        XCTAssertEqual(format.format(.minutes(59)), "59m")
        XCTAssertEqual(format.format(.seconds(3599)), "59m 59s")

        XCTAssertEqual(format.format(.hours(1)), "1h")
        XCTAssertEqual(format.format(.seconds(3661)), "1h 1m 1s")
        XCTAssertEqual(format.format(.seconds(4500)), "1h 15m")
        XCTAssertEqual(format.format(.seconds(7200)), "2h")

        XCTAssertEqual(format.format(.seconds(-1)), "0s")
        XCTAssertEqual(format.format(.seconds(-90)), "0s")
        XCTAssertEqual(format.format(.hours(-1)), "0s")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0s")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0s")
    }

    func testNarrowWithoutSeconds() {
        let format = TimerFormatStyle(style: .narrow, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "0min")

        XCTAssertEqual(format.format(.seconds(1)), "0min")
        XCTAssertEqual(format.format(.seconds(59)), "0min")
        XCTAssertEqual(format.format(.minutes(1)), "1min")
        XCTAssertEqual(format.format(.seconds(119)), "1min")
        XCTAssertEqual(format.format(.seconds(61)), "1min")
        XCTAssertEqual(format.format(.minutes(15)), "15min")
        XCTAssertEqual(format.format(.minutes(59)), "59min")
        XCTAssertEqual(format.format(.seconds(3599)), "59min")

        XCTAssertEqual(format.format(.hours(1)), "1hr")
        XCTAssertEqual(format.format(.seconds(3661)), "1hr 1min")
        XCTAssertEqual(format.format(.seconds(4500)), "1hr 15min")
        XCTAssertEqual(format.format(.seconds(7200)), "2hr")

        XCTAssertEqual(format.format(.seconds(-1)), "0min")
        XCTAssertEqual(format.format(.seconds(-90)), "0min")
        XCTAssertEqual(format.format(.hours(-1)), "0min")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0min")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0min")
    }

    func testNarrowWithSeconds() {
        let format = TimerFormatStyle(style: .narrow, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "0sec")

        XCTAssertEqual(format.format(.seconds(1)), "1sec")
        XCTAssertEqual(format.format(.seconds(59)), "59sec")

        XCTAssertEqual(format.format(.minutes(1)), "1min")
        XCTAssertEqual(format.format(.seconds(119)), "1min 59sec")
        XCTAssertEqual(format.format(.seconds(61)), "1min 1sec")
        XCTAssertEqual(format.format(.minutes(15)), "15min")
        XCTAssertEqual(format.format(.minutes(59)), "59min")
        XCTAssertEqual(format.format(.seconds(3599)), "59min 59sec")

        XCTAssertEqual(format.format(.hours(1)), "1hr")
        XCTAssertEqual(format.format(.seconds(3661)), "1hr 1min 1sec")
        XCTAssertEqual(format.format(.seconds(4500)), "1hr 15min")
        XCTAssertEqual(format.format(.seconds(7200)), "2hr")

        XCTAssertEqual(format.format(.seconds(-1)), "0sec")
        XCTAssertEqual(format.format(.seconds(-90)), "0sec")
        XCTAssertEqual(format.format(.hours(-1)), "0sec")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0sec")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0sec")
    }

    func testWideWithoutSeconds() {
        let format = TimerFormatStyle(style: .wide, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "0 minutes")

        XCTAssertEqual(format.format(.seconds(1)), "0 minutes")
        XCTAssertEqual(format.format(.seconds(59)), "0 minutes")
        XCTAssertEqual(format.format(.minutes(1)), "1 minute")
        XCTAssertEqual(format.format(.seconds(119)), "1 minute")
        XCTAssertEqual(format.format(.seconds(61)), "1 minute")
        XCTAssertEqual(format.format(.minutes(15)), "15 minutes")
        XCTAssertEqual(format.format(.minutes(59)), "59 minutes")
        XCTAssertEqual(format.format(.seconds(3599)), "59 minutes")

        XCTAssertEqual(format.format(.hours(1)), "1 hour")
        XCTAssertEqual(format.format(.seconds(3661)), "1 hour, 1 minute")
        XCTAssertEqual(format.format(.seconds(4500)), "1 hour, 15 minutes")
        XCTAssertEqual(format.format(.seconds(7200)), "2 hours")

        XCTAssertEqual(format.format(.seconds(-1)), "0 minutes")
        XCTAssertEqual(format.format(.seconds(-90)), "0 minutes")
        XCTAssertEqual(format.format(.hours(-1)), "0 minutes")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0 minutes")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0 minutes")
    }

    func testWideWithSeconds() {
        let format = TimerFormatStyle(style: .wide, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "0 seconds")

        XCTAssertEqual(format.format(.seconds(1)), "1 second")
        XCTAssertEqual(format.format(.seconds(59)), "59 seconds")

        XCTAssertEqual(format.format(.minutes(1)), "1 minute")
        XCTAssertEqual(format.format(.seconds(119)), "1 minute, 59 seconds")
        XCTAssertEqual(format.format(.seconds(61)), "1 minute, 1 second")
        XCTAssertEqual(format.format(.minutes(15)), "15 minutes")
        XCTAssertEqual(format.format(.minutes(59)), "59 minutes")
        XCTAssertEqual(format.format(.seconds(3599)), "59 minutes, 59 seconds")

        XCTAssertEqual(format.format(.hours(1)), "1 hour")
        XCTAssertEqual(format.format(.seconds(3661)), "1 hour, 1 minute, 1 second")
        XCTAssertEqual(format.format(.seconds(4500)), "1 hour, 15 minutes")
        XCTAssertEqual(format.format(.seconds(7200)), "2 hours")

        XCTAssertEqual(format.format(.seconds(-1)), "0 seconds")
        XCTAssertEqual(format.format(.seconds(-90)), "0 seconds")
        XCTAssertEqual(format.format(.hours(-1)), "0 seconds")

        XCTAssertEqual(format.format(.seconds(Int.max)), "0 seconds")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0 seconds")
    }

    func testSpellOutWithoutSeconds() {
        let format = TimerFormatStyle(style: .spellOut, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "zero minutes")

        XCTAssertEqual(format.format(.seconds(1)), "zero minutes")
        XCTAssertEqual(format.format(.seconds(59)), "zero minutes")
        XCTAssertEqual(format.format(.minutes(1)), "one minute")
        XCTAssertEqual(format.format(.seconds(119)), "one minute")
        XCTAssertEqual(format.format(.seconds(61)), "one minute")
        XCTAssertEqual(format.format(.minutes(15)), "fifteen minutes")
        XCTAssertEqual(format.format(.minutes(59)), "fifty-nine minutes")
        XCTAssertEqual(format.format(.seconds(3599)), "fifty-nine minutes")

        XCTAssertEqual(format.format(.hours(1)), "one hour")
        XCTAssertEqual(format.format(.seconds(3661)), "one hour, one minute")
        XCTAssertEqual(format.format(.seconds(4500)), "one hour, fifteen minutes")
        XCTAssertEqual(format.format(.seconds(7200)), "two hours")

        XCTAssertEqual(format.format(.seconds(-1)), "zero minutes")
        XCTAssertEqual(format.format(.seconds(-90)), "zero minutes")
        XCTAssertEqual(format.format(.hours(-1)), "zero minutes")

        XCTAssertEqual(format.format(.seconds(Int.max)), "zero minutes")
        XCTAssertEqual(format.format(.seconds(Int.min)), "zero minutes")
    }

    func testSpellOutWithSeconds() {
        let format = TimerFormatStyle(style: .spellOut, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "zero seconds")

        XCTAssertEqual(format.format(.seconds(1)), "one second")
        XCTAssertEqual(format.format(.seconds(59)), "fifty-nine seconds")

        XCTAssertEqual(format.format(.minutes(1)), "one minute")
        XCTAssertEqual(format.format(.seconds(119)), "one minute, fifty-nine seconds")
        XCTAssertEqual(format.format(.seconds(61)), "one minute, one second")
        XCTAssertEqual(format.format(.minutes(15)), "fifteen minutes")
        XCTAssertEqual(format.format(.minutes(59)), "fifty-nine minutes")
        XCTAssertEqual(format.format(.seconds(3599)), "fifty-nine minutes, fifty-nine seconds")

        XCTAssertEqual(format.format(.hours(1)), "one hour")
        XCTAssertEqual(format.format(.seconds(3661)), "one hour, one minute, one second")
        XCTAssertEqual(format.format(.seconds(4500)), "one hour, fifteen minutes")
        XCTAssertEqual(format.format(.seconds(7200)), "two hours")

        XCTAssertEqual(format.format(.seconds(-1)), "zero seconds")
        XCTAssertEqual(format.format(.seconds(-90)), "zero seconds")
        XCTAssertEqual(format.format(.hours(-1)), "zero seconds")

        XCTAssertEqual(format.format(.seconds(Int.max)), "zero seconds")
        XCTAssertEqual(format.format(.seconds(Int.min)), "zero seconds")
    }

    func testDigitsWithoutSeconds() {
        let format = TimerFormatStyle(style: .digits, includeSeconds: false)
        XCTAssertEqual(format.format(.zero), "0:00")

        XCTAssertEqual(format.format(.seconds(1)), "0:00")
        XCTAssertEqual(format.format(.seconds(59)), "0:00")
        XCTAssertEqual(format.format(.minutes(1)), "0:01")
        XCTAssertEqual(format.format(.seconds(119)), "0:01")
        XCTAssertEqual(format.format(.seconds(61)), "0:01")
        XCTAssertEqual(format.format(.minutes(15)), "0:15")
        XCTAssertEqual(format.format(.minutes(59)), "0:59")
        XCTAssertEqual(format.format(.seconds(3599)), "0:59")

        XCTAssertEqual(format.format(.hours(1)), "1:00")
        XCTAssertEqual(format.format(.seconds(3661)), "1:01")
        XCTAssertEqual(format.format(.seconds(4500)), "1:15")
        XCTAssertEqual(format.format(.seconds(7200)), "2:00")

        XCTAssertEqual(format.format(.seconds(-1)), "0:00")
        XCTAssertEqual(format.format(.seconds(-90)), "0:00")
        XCTAssertEqual(format.format(.hours(-1)), "0:00")

        XCTAssertEqual(format.format(.seconds(Int.max)), "2,562,047,788,015,215:30")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0:00")
    }

    func testDigitsWithSeconds() {
        let format = TimerFormatStyle(style: .digits, includeSeconds: true)
        XCTAssertEqual(format.format(.zero), "0:00:00")

        XCTAssertEqual(format.format(.seconds(1)), "0:00:01")
        XCTAssertEqual(format.format(.seconds(59)), "0:00:59")

        XCTAssertEqual(format.format(.minutes(1)), "0:01:00")
        XCTAssertEqual(format.format(.seconds(119)), "0:01:59")
        XCTAssertEqual(format.format(.seconds(61)), "0:01:01")
        XCTAssertEqual(format.format(.minutes(15)), "0:15:00")
        XCTAssertEqual(format.format(.minutes(59)), "0:59:00")
        XCTAssertEqual(format.format(.seconds(3599)), "0:59:59")

        XCTAssertEqual(format.format(.hours(1)), "1:00:00")
        XCTAssertEqual(format.format(.seconds(3661)), "1:01:01")
        XCTAssertEqual(format.format(.seconds(4500)), "1:15:00")
        XCTAssertEqual(format.format(.seconds(7200)), "2:00:00")

        XCTAssertEqual(format.format(.seconds(-1)), "0:00:00")
        XCTAssertEqual(format.format(.seconds(-90)), "0:00:00")
        XCTAssertEqual(format.format(.hours(-1)), "0:00:00")

        XCTAssertEqual(format.format(.seconds(Int.max)), "2,562,047,788,015,215:30:07")
        XCTAssertEqual(format.format(.seconds(Int.min)), "0:00:00")
    }
}
