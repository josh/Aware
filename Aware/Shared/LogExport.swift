//
//  LogExport.swift
//  Aware
//
//  Created by Joshua Peek on 4/23/24.
//

import Foundation
import OSLog

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "LogExport"
)

enum LogExportError: Error {
    case missingLibraryDirectory
}

func exportLogs() async throws -> URL {
    logger.info("Starting OSLog export")

    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let predicate = NSPredicate(format: "subsystem == 'com.awaremac.Aware'")
    let date = Date.now.addingTimeInterval(-3600)
    let position = store.position(date: date)

    await Task.yield()

    logger.debug("Starting to gather entries from OSLogStore")
    let clock = ContinuousClock()
    let start = clock.now
    let entries = try store.getEntries(at: position, matching: predicate)
    logger.debug("Finished gathering logs from OSLogStore in \(clock.now - start)")

    try Task.checkCancellation()

    var data = Data()
    for entry in entries {
        guard let entry = entry as? OSLogEntryLog else { continue }
        let date = entry.date.formatted(date: .omitted, time: .standard)
        let category = entry.category
        let message = entry.composedMessage
        let line = "[\(date)] [\(category)] \(message)\n"
        data.append(contentsOf: line.utf8)
    }

    try Task.checkCancellation()

    guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        throw LogExportError.missingLibraryDirectory
    }
    let fileURL =
        libraryURL
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("Aware.log")
    try data.write(to: fileURL)

    logger.info("Finished OSLog export")

    return fileURL
}
