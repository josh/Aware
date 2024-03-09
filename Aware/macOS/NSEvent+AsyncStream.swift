//
//  NSEvent+AsyncStream.swift
//  Aware
//
//  Created by Joshua Peek on 3/8/24.
//

#if canImport(AppKit)

import AppKit

extension NSEvent {
    static func globalEvents(matching mask: NSEvent.EventTypeMask) -> AsyncStream<NSEvent> {
        AsyncStream { continuation in
            let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
                continuation.yield(event)
            }

            assert(monitor != nil, "failed to add monitor")
            guard let monitor else {
                continuation.finish()
                return
            }

            let sendableMonitor = UncheckedSendable(value: monitor)
            continuation.onTermination = { _ in
                NSEvent.removeMonitor(sendableMonitor.value)
            }
        }
    }
}

private struct UncheckedSendable: @unchecked Sendable {
    var value: Any
}

#endif
