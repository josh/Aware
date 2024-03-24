//
//  Logger+Sendable.swift
//  Aware
//
//  Created by Joshua Peek on 3/23/24.
//

import OSLog

// Assuming that Logger is going to be made Sendable in the future.
extension Logger: @unchecked Sendable {}
