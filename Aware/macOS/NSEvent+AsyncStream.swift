//
//  NSEvent+AsyncStream.swift
//  Aware
//
//  Created by Joshua Peek on 3/8/24.
//

#if canImport(AppKit)

import AppKit

extension NSEvent {
    struct Monitor: @unchecked Sendable {
        /// The event handler object
        let eventMonitor: Any?

        fileprivate init(_ eventMonitor: Any?) {
            self.eventMonitor = eventMonitor
        }

        /// Removes the specified event monitor.
        func cancel() {
            assert(eventMonitor != nil, "event monitor failed to install")
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
            }
        }
    }

    final class Events: AsyncSequence, @unchecked Sendable {
        typealias AsyncIterator = Iterator
        typealias Element = NSEvent

        struct Iterator: AsyncIteratorProtocol {
            private var iterator: AsyncStream<NSEvent>.Iterator

            fileprivate init(iterator: AsyncStream<NSEvent>.Iterator) {
                self.iterator = iterator
            }

            mutating func next() async -> NSEvent? {
                await iterator.next()
            }
        }

        private let stream: AsyncStream<NSEvent>

        fileprivate init(matching mask: NSEvent.EventTypeMask, bufferingPolicy: AsyncStream<NSEvent>.Continuation.BufferingPolicy = .unbounded) {
            let (stream, continuation) = AsyncStream.makeStream(of: NSEvent.self, bufferingPolicy: bufferingPolicy)
            self.stream = stream

            let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
                continuation.yield(event)
            }

            let eventMonitor = Monitor(monitor)
            continuation.onTermination = { [eventMonitor] _ in
                eventMonitor.cancel()
            }
        }

        func makeAsyncIterator() -> Iterator {
            Iterator(iterator: stream.makeAsyncIterator())
        }
    }

    static func globalEvents(matching mask: NSEvent.EventTypeMask) -> NSEvent.Events {
        NSEvent.Events(matching: mask)
    }
}

#endif
