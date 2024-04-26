//
//  NSApplication+Activate.swift
//  Aware
//
//  Created by Joshua Peek on 4/25/24.
//

#if canImport(AppKit)

import AppKit
import OSLog

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "NSApp+Activate"
)

extension NSApplication {
    func activateAggressively() {
        let start: ContinuousClock.Instant = .now
        let deadline: ContinuousClock.Instant = start.advanced(by: .seconds(1))

        Task(priority: .high) {
            while isActive == false && deadline > .now && !Task.isCancelled {
                activate()
                await Task.yield()
            }

            assert(isActive, "expected app to be active")
            logger.debug("\(self) application took \(.now - start) to activate")
        }
    }
}

#endif
