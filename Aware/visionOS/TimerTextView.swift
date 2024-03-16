//
//  TimerTextView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct TimerTextView: View {
    var duration: Duration = .seconds(0)
    var glassBackground: Bool = true

    var body: some View {
        Text(duration, format: .abbreviatedDuration)
            .lineLimit(1)
            .padding()
            .font(.system(size: 900, weight: .medium))
            .minimumScaleFactor(0.01)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassBackgroundEffect(displayMode: glassBackground ? .always : .never)
    }
}

#Preview("0m", traits: .fixedLayout(width: 240, height: 135)) {
    TimerTextView()
}

#Preview("15m", traits: .fixedLayout(width: 240, height: 135)) {
    TimerTextView(duration: .minutes(15))
}

#Preview("1h", traits: .fixedLayout(width: 240, height: 135)) {
    TimerTextView(duration: .hours(1))
}

#Preview("1h 15m", traits: .fixedLayout(width: 240, height: 135)) {
    TimerTextView(duration: .minutes(75))
}

#endif
