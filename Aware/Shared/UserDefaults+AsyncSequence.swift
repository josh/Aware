//
//  UserDefaults+AsyncSequence.swift
//  Aware
//
//  Created by Joshua Peek on 4/23/24.
//

import Foundation
import OSLog

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "UserDefaults+AsyncSequence"
)

extension UserDefaults {
    fileprivate class Observer<Element>: NSObject, @unchecked Sendable {
        private let store: UserDefaults
        private let keyPath: String
        private let block: @Sendable (Element?) -> Void

        init(store: UserDefaults, keyPath: String, block: @escaping @Sendable (Element?) -> Void) {
            self.store = store
            self.keyPath = keyPath
            self.block = block
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            assert(keyPath == self.keyPath, "unexpected keyPath")
            assert(object as? UserDefaults == store, "unexpected store")
            assert(context == nil, "unexpected context")
            block(change?[.newKey] as? Element)
        }

        func cancel() {
            store.removeObserver(self, forKeyPath: keyPath)
        }
    }

    func updates<Element>(
        forKeyPath keyPath: String,
        type _: Element.Type = Element.self,
        initial: Bool = false
    ) -> AsyncStream<Element?> {
        .init(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let observer = Observer<Element>(store: self, keyPath: keyPath) { value in
                logger.debug("Yielding UserDefaults new \"\(keyPath, privacy: .public)\" value")
                continuation.yield(value)
            }

            let options: NSKeyValueObservingOptions = initial ? [.initial, .new] : [.new]
            addObserver(observer, forKeyPath: keyPath, options: options, context: nil)

            continuation.onTermination = { _ in
                logger.debug("Canceling UserDefaults \"\(keyPath, privacy: .public)\" observer")
                observer.cancel()
            }
        }
    }
}
