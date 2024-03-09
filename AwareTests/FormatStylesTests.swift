import XCTest

@testable import Aware

class FormatStyleTests: XCTestCase {
    func testTimeIntervalFormatted() {
        XCTAssertEqual(TimeInterval(15).formatted(.timeDuration), "15")
        XCTAssertEqual(TimeInterval(60).formatted(.timeDuration), "1:00")
        XCTAssertEqual(TimeInterval(15).formatted(.components(style: .spellOut)), "fifteen seconds")
        XCTAssertEqual(TimeInterval(60).formatted(.components(style: .spellOut)), "one minute")
        XCTAssertEqual(TimeInterval(900).formatted(.abbreviatedTimeInterval), "15m")
    }

    func testTimeIntervalAbbreviatedTimeIntervalFormatStyle() {
        let formatter = AbbreviatedTimeIntervalFormatStyle()

        XCTAssertEqual(formatter.format(0), "0m")
        XCTAssertEqual(formatter.format(1), "0m")
        XCTAssertEqual(formatter.format(30), "0m")
        XCTAssertEqual(formatter.format(59), "0m")

        XCTAssertEqual(formatter.format(60), "1m")
        XCTAssertEqual(formatter.format(61), "1m")
        XCTAssertEqual(formatter.format(119), "1m")

        XCTAssertEqual(formatter.format(120), "2m")
        XCTAssertEqual(formatter.format(300), "5m")
        XCTAssertEqual(formatter.format(900), "15m")
        XCTAssertEqual(formatter.format(1800), "30m")
        XCTAssertEqual(formatter.format(2700), "45m")
        XCTAssertEqual(formatter.format(3540), "59m")
        XCTAssertEqual(formatter.format(3599), "59m")

        XCTAssertEqual(formatter.format(3600), "1h")
        XCTAssertEqual(formatter.format(3601), "1h")
        XCTAssertEqual(formatter.format(3660), "1h 1m")
        XCTAssertEqual(formatter.format(4500), "1h 15m")
        XCTAssertEqual(formatter.format(5400), "1h 30m")
        XCTAssertEqual(formatter.format(6300), "1h 45m")

        XCTAssertEqual(formatter.format(7200), "2h")

        XCTAssertEqual(formatter.format(-1), "0m")
        XCTAssertEqual(formatter.format(-90), "0m")
        XCTAssertEqual(formatter.format(-3600), "0m")

        XCTAssertEqual(formatter.format(Double(UInt.max)), "0m")
        XCTAssertEqual(formatter.format(Double.nan), "0m")
        XCTAssertEqual(formatter.format(Double.infinity), "0m")
        XCTAssertEqual(formatter.format(Double.greatestFiniteMagnitude), "0m")
        XCTAssertEqual(formatter.format(Double.leastNormalMagnitude), "0m")
        XCTAssertEqual(formatter.format(Double.leastNonzeroMagnitude), "0m")
    }

    func testDurationFormatted() {
        XCTAssertEqual(Duration.seconds(15).formatted(.time(pattern: .hourMinuteSecond)), "0:00:15")
        XCTAssertEqual(Duration.seconds(15).formatted(.timeDuration), "15")
        XCTAssertEqual(Duration.seconds(60).formatted(.timeDuration), "1:00")
        XCTAssertEqual(Duration.seconds(15).formatted(.components(style: .spellOut)), "fifteen seconds")
        XCTAssertEqual(Duration.seconds(60).formatted(.components(style: .spellOut)), "one minute")
        XCTAssertEqual(Duration.seconds(900).formatted(.abbreviatedDuration), "15m")
    }

    func testDurationAbbreviatedTimeIntervalFormatStyle() {
        let formatter = AbbreviatedDurationFormatStyle()

        XCTAssertEqual(formatter.format(.seconds(0)), "0m")
        XCTAssertEqual(formatter.format(.seconds(1)), "0m")
        XCTAssertEqual(formatter.format(.seconds(30)), "0m")
        XCTAssertEqual(formatter.format(.seconds(59)), "0m")

        XCTAssertEqual(formatter.format(.seconds(60)), "1m")
        XCTAssertEqual(formatter.format(.seconds(61)), "1m")
        XCTAssertEqual(formatter.format(.seconds(119)), "1m")

        XCTAssertEqual(formatter.format(.seconds(120)), "2m")
        XCTAssertEqual(formatter.format(.seconds(300)), "5m")
        XCTAssertEqual(formatter.format(.seconds(900)), "15m")
        XCTAssertEqual(formatter.format(.seconds(1800)), "30m")
        XCTAssertEqual(formatter.format(.seconds(2700)), "45m")
        XCTAssertEqual(formatter.format(.seconds(3540)), "59m")
        XCTAssertEqual(formatter.format(.seconds(3599)), "59m")

        XCTAssertEqual(formatter.format(.seconds(3600)), "1h")
        XCTAssertEqual(formatter.format(.seconds(3601)), "1h")
        XCTAssertEqual(formatter.format(.seconds(3660)), "1h 1m")
        XCTAssertEqual(formatter.format(.seconds(4500)), "1h 15m")
        XCTAssertEqual(formatter.format(.seconds(5400)), "1h 30m")
        XCTAssertEqual(formatter.format(.seconds(6300)), "1h 45m")

        XCTAssertEqual(formatter.format(.seconds(7200)), "2h")

        XCTAssertEqual(formatter.format(.seconds(-1)), "0m")
        XCTAssertEqual(formatter.format(.seconds(-90)), "0m")
        XCTAssertEqual(formatter.format(.seconds(-3600)), "0m")

        XCTAssertEqual(formatter.format(.seconds(Int.max)), "0m")
        XCTAssertEqual(formatter.format(.seconds(Int.min)), "0m")
    }
}
