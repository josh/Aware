//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var glassBackground: Bool

    var body: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
            Spacer()
            Button("Dismiss", systemImage: "xmark") {
                dismiss()
            }
            .labelStyle(.iconOnly)
        }
        .padding(30.0)

        Form {
            Section {
                Toggle("Glass background", isOn: $glassBackground)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview(traits: .fixedLayout(width: 400, height: 250)) {
    SettingsView(
        glassBackground: .constant(true)
    )
}
