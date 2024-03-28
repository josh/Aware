//
//  NotificationCenter+AsyncSequence.swift
//  Aware
//
//  Created by Joshua Peek on 3/23/24.
//

import Foundation

extension NotificationCenter {
    /// Returns an asynchronous sequence of notifications produced by this center for multiple notification names
    /// and optional source object. Similar to calling `AsyncAlgorithms` `merge` over multiple
    /// `notifications(named:object:)`.
    /// - Parameters:
    ///   - names: An array of notification names.
    ///   - object: A source object of notifications.
    /// - Returns: A merged asynchronous sequence of notifications from the center.
    func mergeNotifications(
        named names: [Notification.Name],
        object: AnyObject? = nil
    ) -> MergedNotifications {
        let stream = AsyncStream(bufferingPolicy: .bufferingNewest(7)) { continuation in
            let observers = names.map { name in
                observe(for: name, object: object) { notification in
                    continuation.yield(notification)
                }
            }

            continuation.onTermination = { _ in
                for observer in observers {
                    observer.cancel()
                }
            }
        }

        return MergedNotifications(stream: stream)
    }
}

struct MergedNotifications: AsyncSequence, @unchecked Sendable {
    typealias Element = Notification

    private let stream: AsyncStream<Notification>

    fileprivate init(stream: AsyncStream<Notification>) {
        self.stream = stream
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(iterator: stream.makeAsyncIterator())
    }

    struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncStream<Notification>.Iterator

        fileprivate init(iterator: AsyncStream<Notification>.Iterator) {
            self.iterator = iterator
        }

        mutating func next() async -> Notification? {
            await iterator.next()
        }
    }
}
