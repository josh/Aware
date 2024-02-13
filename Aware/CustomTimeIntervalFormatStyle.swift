//
//  CustomTimeIntervalFormatStyle.swift
//  Aware
//
//  Created by Joshua Peek on 02/12/24.
//  Copyright © 2024 Joshua Peek. All rights reserved.
//

import Foundation

private let bounds = 0 ..< Double(Int.max)

struct CustomTimeIntervalFormatStyle: FormatStyle {
    /// Formats a time interval as a human readable duration string.
    /// - Parameter value: The time interval to format.
    /// - Returns: A string representation of the time interval.
    func format(_ value: TimeInterval) -> String {
        guard bounds.contains(value) else { return "0m" }
        let minutes = Int(value) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}

extension FormatStyle where Self == CustomTimeIntervalFormatStyle {
    static var custom: CustomTimeIntervalFormatStyle { .init() }
}
