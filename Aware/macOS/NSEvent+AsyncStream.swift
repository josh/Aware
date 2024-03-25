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

    static func globalEvents(matching mask: NSEvent.EventTypeMask) -> AsyncStream<NSEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(7)) { continuation in
            let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
                continuation.yield(event)
            }

            let eventMonitor = Monitor(monitor)
            continuation.onTermination = { [eventMonitor] _ in
                eventMonitor.cancel()
            }
        }
    }
}

#endif
