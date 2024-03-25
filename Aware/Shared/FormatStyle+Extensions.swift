//
//  FormatStyles.swift
//  Aware
//
//  Created by Joshua Peek on 02/12/24.
//  Copyright © 2024 Joshua Peek. All rights reserved.
//

import Foundation

/// Wrapper to provide any `Range<Date>` formatter to `TimeInterval`.
struct TimeIntervalFormatStyle<S>: FormatStyle where S: FormatStyle, S.FormatInput == Range<Date> {
    let style: S

    init(_ style: S) {
        self.style = style
    }

    func format(_ value: TimeInterval) -> S.FormatOutput {
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        let range = referenceDate ..< Date(timeIntervalSinceReferenceDate: value)
        return range.formatted(style)
    }
}

/// Wrapper to provide any `Range<Date>` formatter to `Duration`.
struct DurationFormatStyle<S>: FormatStyle where S: FormatStyle, S.FormatInput == Range<Date> {
    let style: S

    init(_ style: S) {
        self.style = style
    }

    func format(_ value: Duration) -> S.FormatOutput {
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        let timeInterval = TimeInterval(value.components.seconds)
        let range = referenceDate ..< Date(timeIntervalSinceReferenceDate: timeInterval)
        return range.formatted(style)
    }
}

extension FormatStyle where Self == TimeIntervalFormatStyle<Date.ComponentsFormatStyle> {
    static func components(
        style: Date.ComponentsFormatStyle.Style,
        fields: Set<Date.ComponentsFormatStyle.Field>? = nil
    ) -> Self {
        .init(Date.ComponentsFormatStyle.components(style: style, fields: fields))
    }

    static var timeDuration: Self {
        .init(Date.ComponentsFormatStyle.timeDuration)
    }
}

extension FormatStyle where Self == DurationFormatStyle<Date.ComponentsFormatStyle> {
    static func components(
        style: Date.ComponentsFormatStyle.Style,
        fields: Set<Date.ComponentsFormatStyle.Field>? = nil
    ) -> Self {
        .init(Date.ComponentsFormatStyle.components(style: style, fields: fields))
    }

    static var timeDuration: Self {
        .init(Date.ComponentsFormatStyle.timeDuration)
    }
}

struct AbbreviatedTimeIntervalFormatStyle: FormatStyle {
    private var style: TimeIntervalFormatStyle<Date.ComponentsFormatStyle> = .components(
        style: .condensedAbbreviated,
        fields: [.hour, .minute]
    )
    private var bounds = 0 ..< Double(Int.max)

    /// Formats a time interval as a human readable duration string.
    /// - Parameter value: The time interval to format.
    /// - Returns: A string representation of the time interval.
    func format(_ value: TimeInterval) -> String {
        guard bounds.contains(value) else { return style.format(0.0) }
        return style.format(value)
    }
}

struct AbbreviatedDurationFormatStyle: FormatStyle {
    private var style: DurationFormatStyle<Date.ComponentsFormatStyle> = .components(
        style: .condensedAbbreviated,
        fields: [.hour, .minute]
    )

    /// Formats a duration as a human readable string.
    /// - Parameter value: The duration to format.
    /// - Returns: A string representation of the duration.
    func format(_ value: Duration) -> String {
        guard value > .zero else { return style.format(Duration.zero) }
        return style.format(value)
    }
}

extension FormatStyle where Self == AbbreviatedTimeIntervalFormatStyle {
    static var abbreviatedTimeInterval: Self { .init() }
}

extension FormatStyle where Self == AbbreviatedDurationFormatStyle {
    static var abbreviatedDuration: Self { .init() }
}
