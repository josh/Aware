import XCTest

@testable import Aware

class NSTimeIntervalFormatterTests: XCTestCase {
    func testStringFromTimeInterval() {
        let formatter = NSTimeIntervalFormatter()

        XCTAssertEqual(formatter.stringFromTimeInterval(0), "0m")
        XCTAssertEqual(formatter.stringFromTimeInterval(1), "0m")
        XCTAssertEqual(formatter.stringFromTimeInterval(30), "0m")
        XCTAssertEqual(formatter.stringFromTimeInterval(59), "0m")

        XCTAssertEqual(formatter.stringFromTimeInterval(60), "1m")
        XCTAssertEqual(formatter.stringFromTimeInterval(61), "1m")
        XCTAssertEqual(formatter.stringFromTimeInterval(119), "1m")

        XCTAssertEqual(formatter.stringFromTimeInterval(120), "2m")
        XCTAssertEqual(formatter.stringFromTimeInterval(300), "5m")
        XCTAssertEqual(formatter.stringFromTimeInterval(900), "15m")
        XCTAssertEqual(formatter.stringFromTimeInterval(1800), "30m")
        XCTAssertEqual(formatter.stringFromTimeInterval(2700), "45m")
        XCTAssertEqual(formatter.stringFromTimeInterval(3540), "59m")
        XCTAssertEqual(formatter.stringFromTimeInterval(3599), "59m")

        XCTAssertEqual(formatter.stringFromTimeInterval(3600), "1h 0m")
        XCTAssertEqual(formatter.stringFromTimeInterval(3601), "1h 0m")
        XCTAssertEqual(formatter.stringFromTimeInterval(3660), "1h 1m")
        XCTAssertEqual(formatter.stringFromTimeInterval(4500), "1h 15m")
        XCTAssertEqual(formatter.stringFromTimeInterval(5400), "1h 30m")
        XCTAssertEqual(formatter.stringFromTimeInterval(6300), "1h 45m")

        XCTAssertEqual(formatter.stringFromTimeInterval(7200), "2h 0m")
    }
}
