//
//  AsyncStream+Extensions.swift
//  Aware
//
//  Created by Joshua Peek on 3/24/24.
//

extension AsyncStream {
    /// Annoying wrapper to get
    /// typealias Yield = @discardableResult (Element) -> Continuation.YieldResult
    struct Yield: Sendable {
        private let continuation: Continuation

        fileprivate init(continuation: Continuation) {
            self.continuation = continuation
        }

        @discardableResult
        func callAsFunction(_ value: Element) -> Continuation.YieldResult {
            continuation.yield(value)
        }
    }

    init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded,
        _ build: @Sendable @escaping (Yield) async -> Void
    ) {
        self.init(elementType, bufferingPolicy: limit) { continuation in
            let task = Task {
                await build(Yield(continuation: continuation))
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
