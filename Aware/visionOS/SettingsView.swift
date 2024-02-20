//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var glassBackground: Bool

    var body: some View {
        ZStack(alignment: .center) {
            HStack {
                Button("Dismiss", systemImage: "xmark") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                Spacer()
            }
            .padding()

            Text("Settings")
                .font(.title)
        }

        Form {
            Section {
                Toggle("Glass background", isOn: $glassBackground)
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 400, height: 250)) {
    SettingsView(
        glassBackground: .constant(true)
    )
}

#endif
