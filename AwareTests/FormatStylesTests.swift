import XCTest

@testable import Aware

class FormatStyleTests: XCTestCase {
    func testFormatted() {
        XCTAssertEqual(TimeInterval(60).formatted(.timeDuration), "1:00")
        XCTAssertEqual(TimeInterval(60).formatted(.components(style: .spellOut)), "one minute")
        XCTAssertEqual(TimeInterval(900).formatted(.abbreviatedTimeInterval), "15m")
    }

    func testAbbreviatedTimeIntervalFormatStyle() {
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
}
