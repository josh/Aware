import XCTest

@testable import Aware

final class NotificationCenterTests: XCTestCase {
    let center = NotificationCenter.default
    let fooNotification = Notification.Name("fooNotification")
    let barNotification = Notification.Name("barNotification")
    let userInfo = ["message": "Hello, world!"]

    func testSendableObserver() {
        let expectation = self.expectation(description: "fooNotification")

        let observer = center.observe(for: fooNotification) { [userInfo] notification in
            XCTAssertEqual(notification.name.rawValue, "fooNotification")
            XCTAssertEqual(notification.userInfo as? [String: String], userInfo)
            expectation.fulfill()
        }

        center.post(name: fooNotification, object: nil, userInfo: userInfo)
        center.post(name: barNotification, object: nil, userInfo: userInfo)
        wait(for: [expectation], timeout: 1.0)

        observer.cancel()
    }

    func testMergeNotifications() {
        let fooExpectation = expectation(description: "fooNotification")
        let barExpectation = expectation(description: "barNotification")

        let consumerTask = Task { [center, fooNotification, barNotification] in
            for await notification in center.mergeNotifications(named: [fooNotification, barNotification]) {
                if notification.name.rawValue == "fooNotification" {
                    fooExpectation.fulfill()
                }
                if notification.name.rawValue == "barNotification" {
                    barExpectation.fulfill()
                }
            }
        }

        let producerTask = Task { [center, fooNotification, barNotification, userInfo] in
            try? await Task.sleep(for: .milliseconds(100))
            center.post(name: fooNotification, object: nil, userInfo: userInfo)
            center.post(name: barNotification, object: nil, userInfo: userInfo)
        }

        wait(for: [fooExpectation, barExpectation], timeout: 1.0)
        consumerTask.cancel()
        producerTask.cancel()
    }
}
