import XCTest

@testable import Aware

final class WatchChannelTests: XCTestCase {
    func testSendToNoSubscribers() async throws {
        let channel = WatchChannel<Int>()

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(2)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(3)
            try await Task.sleep(for: .milliseconds(100))
            channel.finish()
        }

        _ = try await producer.value
    }

    func testSendSingleValue() async throws {
        let channel = WatchChannel<Int>()

        let consumer = Task {
            for await value in channel.subscribe() {
                return value
            }
            return -1
        }

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
        }

        _ = try await producer.value
        let value = await consumer.value
        XCTAssertEqual(value, 1)
    }

    func testSendSingleValueAndFinish() async throws {
        let channel = WatchChannel<Int>()

        let consumer = Task {
            var lastValue: Int = -1
            for await value in channel.subscribe() {
                lastValue = value
            }
            return lastValue
        }

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
            try await Task.sleep(for: .milliseconds(100))
            channel.finish()
        }

        _ = try await producer.value
        let value = await consumer.value
        XCTAssertEqual(value, 1)
    }

    func testSendMultipleValuesAndFinish() async throws {
        let channel = WatchChannel<Int>()

        let consumer = Task {
            var values: [Int] = []
            for await value in channel.subscribe() {
                values.append(value)
            }
            return values
        }

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(2)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(3)
            try await Task.sleep(for: .milliseconds(100))
            channel.finish()
        }

        _ = try await producer.value
        let values = await consumer.value
        XCTAssertEqual(values, [1, 2, 3])
    }

    func testSendToMultipleSubscribers() async throws {
        let channel = WatchChannel<Int>()

        let consumer1 = Task {
            for await value in channel.subscribe() {
                return value
            }
            return -1
        }

        let consumer2 = Task {
            for await value in channel.subscribe() {
                return value
            }
            return -1
        }

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
        }

        _ = try await producer.value
        let value1 = await consumer1.value
        XCTAssertEqual(value1, 1)
        let value2 = await consumer2.value
        XCTAssertEqual(value2, 1)
    }

    func testSubscriberCancelStopsSubscription() async throws {
        let channel = WatchChannel<Int>()

        let consumer = Task {
            var values: [Int] = []
            let subscription = channel.subscribe()
            for await value in subscription {
                values.append(value)
                subscription.cancel()
            }
            return values
        }

        let producer = Task {
            try await Task.sleep(for: .milliseconds(100))
            channel.send(1)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(2)
            try await Task.sleep(for: .milliseconds(100))
            channel.send(3)
            try await Task.sleep(for: .milliseconds(100))
            channel.finish()
        }

        _ = try await producer.value
        let values = await consumer.value
        XCTAssertEqual(values, [1])
    }

    func testSubscriberCancelsMultipleTimes() async throws {
        let channel = WatchChannel<Int>()

        let consumer = Task {
            let subscription = channel.subscribe()
            subscription.cancel()
            subscription.cancel()
            subscription.cancel()
        }

        _ = await consumer.value
    }
}
