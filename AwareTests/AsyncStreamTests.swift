import XCTest

@testable import Aware

final class AsyncStreamTests: XCTestCase {
    func testSimpleAsyncStream() async throws {
        @Sendable func answer() async -> Int {
            42
        }

        let stream = AsyncStream { [answer] yield in
            let n = await answer()
            yield(n)
            yield(n + 1)
            yield(n + 2)
        }

        var numbers: [Int] = []
        for await n in stream {
            numbers.append(n)
        }

        XCTAssertEqual(numbers, [42, 43, 44])
    }

    func testMapAsyncStream() async throws {
        let stream1 = AsyncStream { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let stream2 = AsyncStream { yield in
            for await n in stream1 {
                yield(n * 2)
            }
        }

        var numbers: [Int] = []
        for await n in stream2 {
            numbers.append(n)
        }

        XCTAssertEqual(numbers, [2, 4, 6])
    }
}
