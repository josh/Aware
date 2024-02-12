import XCTest

@testable import Aware

class CustomTimeIntervalFormatStyleTests: XCTestCase {
    func testFormat() {
        let formatter = CustomTimeIntervalFormatStyle()

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

        XCTAssertEqual(formatter.format(3600), "1h 0m")
        XCTAssertEqual(formatter.format(3601), "1h 0m")
        XCTAssertEqual(formatter.format(3660), "1h 1m")
        XCTAssertEqual(formatter.format(4500), "1h 15m")
        XCTAssertEqual(formatter.format(5400), "1h 30m")
        XCTAssertEqual(formatter.format(6300), "1h 45m")

        XCTAssertEqual(formatter.format(7200), "2h 0m")
    }
}
