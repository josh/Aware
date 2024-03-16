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
    static func minutes<T: BinaryInteger>(_ minutes: T) -> Duration {
        return seconds(minutes * 60)
    }

    /// Construct a Duration given a number of hours represented as a BinaryInteger.
    /// - Returns: A Duration representing a given number of hours.
    static func hours<T: BinaryInteger>(_ hours: T) -> Duration {
        return minutes(hours * 60)
    }
}
