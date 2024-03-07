//
//  NSEvent+Publisher.swift
//  Aware
//
//  Created by Joshua Peek on 3/6/24.
//

#if canImport(AppKit)

import AppKit
import Combine

struct NSEventGlobalPublisher: Combine.Publisher {
    typealias Output = NSEvent
    typealias Failure = Never

    let mask: NSEvent.EventTypeMask

    func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = NSEventGlobalSubscription(mask: mask, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class NSEventGlobalSubscription<S>: Combine.Subscription where S: Subscriber, S.Input == NSEvent {
    private var subscriber: S?
    private var monitor: Any?

    init(mask: NSEvent.EventTypeMask, subscriber: S) {
        self.subscriber = subscriber
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            _ = self?.subscriber?.receive(event)
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func request(_: Subscribers.Demand) {}

    func cancel() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        subscriber = nil
    }
}

#endif
