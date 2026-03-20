//
//  SettingsSupportViews.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct SettingsFormContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            content
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct SettingsHelpCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

struct SettingsLockedNotice: View {
    let text: String

    var body: some View {
        SettingsHelpCaption(text: text)
            .padding(.top, 6)
    }
}

struct SettingsSliderRow: View {
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let isEnabled: Bool
    let valueText: String
    let sliderIdentifier: String

    var body: some View {
        VStack {
            Slider(value: value, in: range, step: step)
                .disabled(isEnabled == false)
                .accessibilityIdentifier(sliderIdentifier)
                .padding(.horizontal, 50)
                .padding(.bottom, 5)
            Text(valueText)
                .font(.headline)
        }
        .padding(.horizontal, 10)
    }
}

struct SettingsPercentSliderRow: View {
    let title: String
    let value: Binding<Double>
    let valueText: String
    let isEnabled: Bool
    let sliderIdentifier: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Slider(value: value, in: 0...1, step: 0.05)
                .disabled(isEnabled == false)
                .accessibilityIdentifier(sliderIdentifier)
            Text(valueText)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(isEnabled ? .primary : .secondary)
        }
    }
}
