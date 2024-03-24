//
//  Duration+Extensions.swift
//  Aware
//
//  Created by Joshua Peek on 3/15/24.
//

import Foundation

extension Duration {
    /// Construct a Duration given a number of minutes represented as a BinaryInteger.
    /// - Returns: A Duration representing a given number of minutes.
    static func minutes(_ minutes: some BinaryInteger) -> Duration {
        seconds(minutes * 60)
    }

    /// Construct a Duration given a number of hours represented as a BinaryInteger.
    /// - Returns: A Duration representing a given number of hours.
    static func hours(_ hours: some BinaryInteger) -> Duration {
        minutes(hours * 60)
    }
}
