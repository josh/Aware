//
//  NotificationCenter+Observer.swift
//  Aware
//
//  Created by Joshua Peek on 3/16/24.
//

import Foundation

extension NotificationCenter {
    struct Observer: @unchecked Sendable {
        /// The notification center this observer uses.
        private let center: NotificationCenter

        /// Reference to internal non-sendable `NSNotificationReceiver` object.
        /// See apple/swift-corelibs-foundation for source.
        private let observer: AnyObject

        /// Create sendable Observer wrapper around `NSNotificationReceiver`.
        fileprivate init(center: NotificationCenter, observer: AnyObject) {
            self.center = center
            self.observer = observer
        }

        /// Removes observer from the notification center's dispatch table.
        func cancel() {
            center.removeObserver(observer)
        }
    }

    /// Adds an entry to the notification center to receive notifications that passed to the provided block.
    func observe(
        for name: Notification.Name,
        object: AnyObject? = nil,
        using block: @Sendable @escaping (Notification) -> Void
    ) -> Observer {
        let observer = addObserver(
            forName: name,
            object: object,
            queue: nil,
            using: block
        )
        return Observer(center: self, observer: observer)
    }
}
