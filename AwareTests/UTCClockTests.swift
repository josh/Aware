import XCTest

@testable import Aware

final class UTCClockTests: XCTestCase {
    func testSleep() async throws {
        try await UTCClock().sleep(for: .seconds(1))
    }

    func testAdvancedByDuration() throws {
        let now = UTCClock().now
        let then = now.advanced(by: .seconds(15))
        XCTAssertEqual(now.duration(to: then), .seconds(15))
        XCTAssertEqual(then.duration(to: now), .seconds(-15))
    }

    func testDurationToTimeInterval() throws {
        XCTAssertEqual(Duration.seconds(0).timeInterval, 0.0)
        XCTAssertEqual(Duration.seconds(60).timeInterval, 60.0)

        XCTAssertEqual(Duration.milliseconds(0).timeInterval, 0.0)
        XCTAssertEqual(Duration.milliseconds(50).timeInterval, 0.05)
        XCTAssertEqual(Duration.milliseconds(1500).timeInterval, 1.5)

        XCTAssertEqual(Duration.microseconds(0).timeInterval, 0.0)
        XCTAssertEqual(Duration.microseconds(50).timeInterval, 0.00005)
    }

    func testTimeIntervalToDuration() throws {
        XCTAssertEqual(Duration(timeInterval: 0.0), .seconds(0))
        XCTAssertEqual(Duration(timeInterval: 60.0), .seconds(60))

        XCTAssertEqual(Duration(timeInterval: 0.05), .milliseconds(50))
        XCTAssertEqual(Duration(timeInterval: 1.5), .milliseconds(1500))

        XCTAssertEqual(Duration(timeInterval: 0.00005), .microseconds(50))
    }
}
