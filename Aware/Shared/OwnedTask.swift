//
//  OwnedTask.swift
//  Aware
//
//  Created by Joshua Peek on 3/16/24.
//

/// A wrapper around Swift Tasks to provide RAII style cancellation when handle is dropped.
/// Normally tasks run regardless of whether you keep a reference to it. This flips that behavior.
/// You'll likely want to capture self weakly when using this pattern to avoid retain cycles.
class OwnedTask<Success, Failure> where Success: Sendable, Failure: Error {
    private var task: Task<Success, Failure>

    fileprivate init(task: Task<Success, Failure>) {
        self.task = task
    }

    deinit {
        task.cancel()
    }

    /// Indicates that the task should stop running.
    func cancel() {
        task.cancel()
    }

    /// A Boolean value that indicates whether the task should stop executing.
    var isCancelled: Bool {
        task.isCancelled
    }
}

extension Task {
    /// Returns owned reference to Task.
    var owned: OwnedTask<Success, Failure> {
        .init(task: self)
    }
}
