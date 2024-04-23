//
//  TimerFormatStyle.swift
//  Aware
//
//  Created by Joshua Peek on 4/22/24.
//

import Foundation

struct TimerFormatStyle: FormatStyle, Codable {
    enum Style: String, CaseIterable, Codable {
        // 1 hr, 15 min
        case abbreviated

        // 1h 15m
        case condensedAbbreviated

        // 1hr 15min
        case narrow

        // 1 hour, 15 minutes
        case wide

        // one hour, fifteen minutes
        case spellOut

        // 1:15
        case digits

        var exampleText: String {
            switch self {
            case .abbreviated: return "1 hr, 15 min"
            case .condensedAbbreviated: return "1h 15m"
            case .narrow: return "1hr 15min"
            case .wide: return "1 hour, 15 minutes"
            case .spellOut: return "one hour, fifteen minutes"
            case .digits: return "1:15"
            }
        }
    }

    var style: Style
    var showSeconds: Bool

    func format(_ value: Duration) -> String {
        let clampedValue = value < .zero ? .zero : value

        switch style {
        case .digits:
            let pattern: Duration.TimeFormatStyle.Pattern =
                showSeconds
                    ? .hourMinuteSecond(padHourToLength: 1)
                    : .hourMinute(padHourToLength: 1, roundSeconds: .down)
            let format: Duration.TimeFormatStyle = .time(pattern: pattern)
            return format.format(clampedValue)

        case .abbreviated, .condensedAbbreviated, .narrow, .wide, .spellOut:
            let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
            let timeInterval = TimeInterval(clampedValue.components.seconds)
            let range = referenceDate ..< Date(timeIntervalSinceReferenceDate: timeInterval)

            let componentsFormatFields: Set<Date.ComponentsFormatStyle.Field> =
                if showSeconds {
                    [.hour, .minute, .second]
                } else {
                    [.hour, .minute]
                }

            let componentsFormatStyle: Date.ComponentsFormatStyle.Style =
                switch style {
                case .abbreviated: .abbreviated
                case .condensedAbbreviated: .condensedAbbreviated
                case .narrow: .narrow
                case .spellOut: .spellOut
                case .wide: .wide
                case .digits: fatalError("unreachable")
                }

            let formatStyle: Date.ComponentsFormatStyle = .components(
                style: componentsFormatStyle, fields: componentsFormatFields
            )

            return formatStyle.format(range)
        }
    }

    /// Return interval formatted text needs to be updated at depending on if seconds are shown.
    /// Also see <https://github.com/apple/swift-foundation/blob/main/Proposals/0003-discrete-format-style.md>
    var refreshInterval: TimeInterval {
        showSeconds ? 1.0 : 60.0
    }
}
