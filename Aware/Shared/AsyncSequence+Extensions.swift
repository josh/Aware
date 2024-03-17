//
//  AsyncSequence+Extensions.swift
//  Aware
//
//  Created by Joshua Peek on 3/16/24.
//

import Foundation

// MARK: AsyncSequence+AsyncVoidSequence

extension AsyncSequence {
    // Ideally we could just write something like:
    //
    // var maskElements: some AsyncSequence<Void> {
    //    map { _ in () }
    // }
    //
    // But it's block on newer opaque result type features. See
    // https://github.com/apple/swift-evolution/blob/main/proposals/0358-primary-associated-types-in-stdlib.md#alternatives-considered

    /// Return sequence masking element values. Useful when the sequence's elements aren't `Sendable` like `Notification` or `NSEvent`.
    var maskElements: AsyncVoidSequence<Self> {
        AsyncVoidSequence(self)
    }
}

struct AsyncVoidSequence<Base>: AsyncSequence where Base: AsyncSequence {
    typealias Element = Void
    typealias AsyncIterator = AsyncVoidIterator<Base.AsyncIterator>

    private let base: Base

    fileprivate init(_ base: Base) {
        self.base = base
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base.makeAsyncIterator())
    }
}

struct AsyncVoidIterator<Base>: AsyncIteratorProtocol where Base: AsyncIteratorProtocol {
    typealias Element = Void

    private var base: Base

    fileprivate init(_ base: Base) {
        self.base = base
    }

    mutating func next() async rethrows -> Void? {
        if let _ = try await base.next() {
            return ()
        } else {
            return nil
        }
    }
}

extension AsyncVoidSequence: Sendable where Base: Sendable {}
extension AsyncVoidIterator: Sendable where Base: Sendable {}
