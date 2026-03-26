//
//  SettingsTabViews.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct SettingsGameTab: View {
    let maximumGuesses: Binding<Int>
    let answerLengthDraft: Binding<String>
    let enableCelebration: Binding<Bool>
    let canEditSettings: Bool
    let answerLengthFocus: FocusState<Bool>.Binding
    let showAnswerLengthError: Bool
    let onAnswerLengthChange: (String) -> Void
    let onFinalizeAnswerLength: () -> Void

    var body: some View {
        TextField("Maximum guesses:", value: maximumGuesses, format: .number)
            .help(localized("help.settings.maximum_guesses"))
            .disabled(canEditSettings == false)
            .accessibilityIdentifier("settingsMaximumGuessesField")
            .padding(.bottom, 5)

        TextField("Answer length:", text: answerLengthDraft)
            .help(localized("help.settings.answer_length"))
            .focused(answerLengthFocus)
            .disabled(canEditSettings == false)
            .accessibilityIdentifier("answerLengthField")
            .onChange(of: answerLengthDraft.wrappedValue) { newValue, _ in
                onAnswerLengthChange(newValue)
            }
            .onSubmit(onFinalizeAnswerLength)
            .onChange(of: answerLengthFocus.wrappedValue) { _, focused in
                if focused == false {
                    onFinalizeAnswerLength()
                }
            }

        if showAnswerLengthError {
            Text("Must be between 3 and 8")
                .foregroundStyle(.red)
                .accessibilityIdentifier("answerLengthError")
        }

        Toggle("Enable celebration", isOn: enableCelebration)
            .disabled(canEditSettings == false)
            .accessibilityIdentifier("settingsEnableCelebrationToggle")
            .padding(.top, 8)
    }
}

struct SettingsAdvancedTab: View {
    let enableRepeats: Binding<Bool>
    let enableHardMode: Binding<Bool>
    let showGuessCount: Binding<Bool>
    let enablePerGuessTimeLimit: Binding<Bool>
    let perGuessTimeLimitSeconds: Binding<Double>
    let perGuessTimeLimitValue: Int
    let enableGameTimeLimit: Binding<Bool>
    let gameTimeLimitSeconds: Binding<Double>
    let gameTimeLimitValue: Int
    let canEditSettings: Bool
    let gameInProgress: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            SettingsSectionTitle(text: "Rules")

            Toggle("Enable repeating", isOn: enableRepeats)
                .help(localized("help.settings.enable_repeating"))
                .disabled(canEditSettings == false)
                .accessibilityIdentifier("settingsEnableRepeatsToggle")
                .padding(.bottom, 5)

            Toggle("Enable hard mode", isOn: enableHardMode)
                .help(localized("help.settings.enable_hard_mode"))
                .disabled(canEditSettings == false)
                .accessibilityIdentifier("settingsEnableHardModeToggle")
                .padding(.bottom, 5)

            Toggle("Show guess count", isOn: showGuessCount)
                .help(localized("help.settings.show_guess_count"))
                .disabled(canEditSettings == false)
                .accessibilityIdentifier("settingsShowGuessCountToggle")
                .padding(.bottom, 10)

            Divider()
                .padding(.vertical, 20)

            SettingsSectionTitle(text: "Timers")

            Toggle(localized("settings.timer.per_guess.enable"), isOn: enablePerGuessTimeLimit)
                .help(localized("help.settings.enable_per_guess_time_limit"))
                .disabled(canEditSettings == false)
                .accessibilityIdentifier("settingsPerGuessTimerToggle")
                .padding(.bottom, 5)

            SettingsSliderRow(
                value: perGuessTimeLimitSeconds,
                range: 5...180,
                step: 5,
                isEnabled: enablePerGuessTimeLimit.wrappedValue && canEditSettings,
                valueText: localized("settings.timer.per_guess.value", perGuessTimeLimitValue),
                sliderIdentifier: "settingsPerGuessTimerSlider"
            )
            .padding(.bottom, 20)

            Toggle(localized("settings.timer.game.enable"), isOn: enableGameTimeLimit)
                .help(localized("help.settings.enable_game_time_limit"))
                .disabled(canEditSettings == false)
                .accessibilityIdentifier("settingsGameTimerToggle")
                .padding(.bottom, 5)

            SettingsSliderRow(
                value: gameTimeLimitSeconds,
                range: 300...1800,
                step: 60,
                isEnabled: enableGameTimeLimit.wrappedValue && canEditSettings,
                valueText: localized("settings.timer.game.value", gameTimeLimitValue),
                sliderIdentifier: "settingsGameTimerSlider"
            )

            if gameInProgress {
                SettingsLockedNotice(text: localized("settings.warning.timer_locked_during_game"))
            }
        }
    }
}

struct SettingsSoundTab: View {
    let enableSoundEffects: Binding<Bool>
    let soundEffectsVolume: Binding<Double>
    let soundEffectsVolumeValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionTitle(text: "Sound Effects")

            Toggle("Enable sound effects", isOn: enableSoundEffects)
                .help(localized("help.settings.sound_effects"))
                .accessibilityIdentifier("settingsSoundEffectsToggle")

            SettingsPercentSliderRow(
                title: "Volume",
                value: soundEffectsVolume,
                valueText: "\(Int(soundEffectsVolumeValue * 100))%",
                isEnabled: enableSoundEffects.wrappedValue,
                sliderIdentifier: "settingsSoundEffectsSlider"
            )
        }
        .padding(.vertical, 6)
    }
}

struct SettingsLanguageTab: View {
    let appLanguageCode: Binding<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle(text: "App Language")

            Picker("App Language", selection: appLanguageCode) {
                Text("Follow System").tag("system")
                    .padding(.bottom, 2)
                Text("English").tag("en")
                    .padding(.bottom, 2)
                Text("Magyar").tag("hu")
                    .padding(.bottom, 2)
            }
            .pickerStyle(.radioGroup)
            .accessibilityIdentifier("settingsLanguagePicker")

            SettingsHelpCaption(text: "Some language changes require restart.")
                .padding(.top, 10)
        }
    }
}

struct SettingsMusicTab: View {
    let enableBackgroundMusic: Binding<Bool>
    let backgroundMusicTrackID: Binding<String>
    let backgroundMusicVolume: Binding<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionTitle(text: "Background Music")

            Toggle(localized("settings.music.enable"), isOn: enableBackgroundMusic)
                .accessibilityIdentifier("settingsBackgroundMusicToggle")

            Picker(localized("settings.music.track"), selection: backgroundMusicTrackID) {
                ForEach(SoundPlayer.availableBackgroundTracks) { track in
                    Text(track.displayName).tag(track.id)
                }
            }
            .disabled(enableBackgroundMusic.wrappedValue == false)
            .accessibilityIdentifier("settingsBackgroundMusicPicker")

            SettingsPercentSliderRow(
                title: "Volume",
                value: backgroundMusicVolume,
                valueText: "\(Int(backgroundMusicVolume.wrappedValue * 100))%",
                isEnabled: enableBackgroundMusic.wrappedValue,
                sliderIdentifier: "settingsBackgroundMusicSlider"
            )
        }
        .padding(.vertical, 6)
    }
}

struct SettingsThemeTab: View {
    let animalThemes: [AnimalTheme]
    let selectedThemeID: String
    let onSelectTheme: (AnimalTheme) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionTitle(text: "Animal Theme")

                ForEach(animalThemes) { theme in
                    ThemeRowView(
                        theme: theme,
                        isSelected: selectedThemeID == theme.id,
                        onSelect: {
                            onSelectTheme(theme)
                        },
                        accessibilityIdentifier: "settingsThemeRow_\(theme.id)"
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ThemeRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: AnimalTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let accessibilityIdentifier: String

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(theme.bullAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .animalIconStyle()

                Image(theme.cowAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .animalIconStyle()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(previewBackgroundColor)
            )
            .padding(.trailing, 10)

            Text(localized(theme.nameKey))
                .foregroundStyle(.primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityValue(isSelected ? "selected" : "notSelected")
        .onTapGesture(perform: onSelect)
    }

    private var previewBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var rowBackgroundColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
        }
        return colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
    }
}
