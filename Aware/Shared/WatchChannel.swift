//
//  WatchChannel.swift
//  Aware
//
//  Created by Joshua Peek on 3/17/24.
//

import Foundation
import os.lock

/// A single-producer, multi-consumer channel. Many values can be sent, but no history is kept.
/// Receivers only see the most recent value.
struct WatchChannel<Element> where Element: Sendable {
    private let protectedSubscriptions: OSAllocatedUnfairLock<[UUID: Subscription]> =
        OSAllocatedUnfairLock(initialState: [:])

    private var subscriptions: [UUID: Subscription] {
        protectedSubscriptions.withLock { $0 }
    }

    func send(_ value: Element) {
        for subscription in subscriptions.values {
            subscription.continuation.yield(value)
        }
    }

    func finish() {
        for subscription in subscriptions.values {
            subscription.continuation.finish()
        }
    }

    func subscribe() -> Subscription {
        let subscription = Subscription(protectedSubscriptions: protectedSubscriptions)
        protectedSubscriptions.withLock { subscriptions in
            subscriptions[subscription.id] = subscription
        }
        return subscription
    }

    final class Subscription: AsyncSequence, Sendable {
        fileprivate let id = UUID()
        private let protectedSubscriptions: OSAllocatedUnfairLock<[UUID: Subscription]>
        private let stream: AsyncStream<Element>
        fileprivate let continuation: AsyncStream<Element>.Continuation

        fileprivate init(protectedSubscriptions: OSAllocatedUnfairLock<[UUID: Subscription]>) {
            self.protectedSubscriptions = protectedSubscriptions

            let (stream, continuation) = AsyncStream<Element>.makeStream(
                bufferingPolicy: .bufferingNewest(1))
            self.stream = stream
            self.continuation = continuation
        }

        deinit {
            cancel()
        }

        func cancel() {
            _ = protectedSubscriptions.withLock { subscriptions in subscriptions.removeValue(forKey: id) }
            continuation.finish()
        }

        func makeAsyncIterator() -> Iterator {
            Iterator(iterator: stream.makeAsyncIterator())
        }
    }

    struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncStream<Element>.Iterator

        fileprivate init(iterator: AsyncStream<Element>.Iterator) {
            self.iterator = iterator
        }

        mutating func next() async -> Element? {
            await iterator.next()
        }
    }
}
