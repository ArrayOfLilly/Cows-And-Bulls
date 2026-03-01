//
//  SettingsView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 25..
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("maximumGuesses") private var maximumGuesses = 10
    @AppStorage("answerLength") private var answerLength = 4
    @AppStorage("enableRepeats") private var enableRepeats = false
    @AppStorage("enableHardMode") private var enableHardMode = false
    @AppStorage("showGuessCount") private var showGuessCount = false
    @AppStorage("enablePerGuessTimeLimit") private var enablePerGuessTimeLimit = false
    @AppStorage("enableGameTimeLimit") private var enableGameTimeLimit = false
    @AppStorage("perGuessTimeLimitSeconds") private var perGuessTimeLimitSeconds = 30
    @AppStorage("gameTimeLimitSeconds") private var gameTimeLimitSeconds = 300
    @AppStorage("enableSoundEffects") private var enableSoundEffects = true
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume = 0.8
    @AppStorage("enableBackgroundMusic") private var enableBackgroundMusic = false
    @AppStorage("backgroundMusicTrackID") private var backgroundMusicTrackID = "Mushroom Background Music"
    @AppStorage("backgroundMusicVolume") private var backgroundMusicVolume = 0.35
    @AppStorage("appLanguageCode") private var appLanguageCode = "system"
    @State private var previousLanguageCode = "system"
    @State private var showRestartPrompt = false

    @AppStorage("selectedAnimalThemeID") private var selectedAnimalThemeID = "classic"
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"

    private let animalThemes: [AnimalTheme] = [
        .init(id: "classic", nameKey: "theme.classic", bullAsset: "Bull", cowAsset: "Cow"),
        .init(id: "geometric", nameKey: "theme.geometric", bullAsset: "Bull9", cowAsset: "Cow9"),
        .init(id: "vivid", nameKey: "theme.vivid", bullAsset: "Bull5", cowAsset: "Cow5"),
        .init(id: "chubby", nameKey: "theme.chubby", bullAsset: "Bull7", cowAsset: "Cow7"),
        .init(id: "classic 2", nameKey: "theme.classic2", bullAsset: "Bull10", cowAsset: "Cow10"),
        .init(id: "black&white", nameKey: "theme.black_white", bullAsset: "Bull13.3", cowAsset: "Cow13.2"),
        .init(id: "modern", nameKey: "theme.modern", bullAsset: "Bull14", cowAsset: "Cow4"),
        .init(id: "faces", nameKey: "theme.faces", bullAsset: "Bull15", cowAsset: "Cow15"),
        .init(id: "buffalo", nameKey: "theme.buffalo", bullAsset: "Bull19", cowAsset: "Cow10"),
        .init(id: "marriage story", nameKey: "theme.marriage_story", bullAsset: "Bull20", cowAsset: "Cow24"),
        .init(id: "faces 2", nameKey: "theme.faces2", bullAsset: "Bull22", cowAsset: "Cow23.2")
    ]

    var body: some View {
        TabView {
            gameTab
            advancedTab
            soundTab
            musicTab
            languageTab
            themeTab
        }
        .frame(width: 420, height: 400)
        .onAppear {
            previousLanguageCode = appLanguageCode
            if animalThemes.contains(where: { $0.id == selectedAnimalThemeID }) == false {
                if let matchedTheme = animalThemes.first(where: {
                    $0.bullAsset == selectedBullAssetName && $0.cowAsset == selectedCowAssetName
                }) {
                    selectedAnimalThemeID = matchedTheme.id
                } else if let firstTheme = animalThemes.first {
                    applyTheme(firstTheme)
                }
            }
        }
        .confirmationDialog(
            localized("Restart required"),
            isPresented: $showRestartPrompt,
            titleVisibility: .visible
        ) {
            Button(localized("Restart now"), role: .destructive) {
                restartApplication()
            }
            Button(localized("Later"), role: .cancel) {}
        } message: {
            Text(localized("Language change may require app restart. Restart now?"))
        }
        .onAppear {
            applyMusicSettings()
        }
        .onChange(of: enableBackgroundMusic) {
            applyMusicSettings()
        }
        .onChange(of: backgroundMusicTrackID) {
            applyMusicSettings()
        }
        .onChange(of: backgroundMusicVolume) {
            applyMusicSettings()
        }
    }

    private func applyTheme(_ theme: AnimalTheme) {
        selectedAnimalThemeID = theme.id
        selectedBullAssetName = theme.bullAsset
        selectedCowAssetName = theme.cowAsset
    }

    private func restartApplication() {
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.open(appURL)
        NSApp.terminate(nil)
    }

    private func applyMusicSettings() {
        SoundPlayer.shared.updateBackgroundMusic(
            enabled: enableBackgroundMusic,
            trackID: backgroundMusicTrackID,
            volume: backgroundMusicVolume
        )
    }

    private var gameTab: some View {
        Form {
            TextField("Maximum guesses:", value: $maximumGuesses, format: .number)
                .help(localized("help.settings.maximum_guesses"))

            TextField("Answer length:", value: $answerLength, format: .number)
                .help(localized("help.settings.answer_length"))

            if answerLength < 3 || answerLength > 8 {
                Text("Must be between 3 and 8")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Settings")
        .tabItem {
            Label("Game", image: "Cow")
        }
    }

    private var advancedTab: some View {
        Form {
            Toggle("Enable repeating", isOn: $enableRepeats)
                .help(localized("help.settings.enable_repeating"))
            Toggle("Enable hard mode", isOn: $enableHardMode)
                .help(localized("help.settings.enable_hard_mode"))
            Toggle("Show guess count", isOn: $showGuessCount)
                .help(localized("help.settings.show_guess_count"))

            Divider()
                .padding(.vertical, 4)

            Toggle("Enable per-guess time limit", isOn: $enablePerGuessTimeLimit)
                .help(localized("help.settings.enable_per_guess_time_limit"))
            Stepper(
                localized("Per-guess limit: %lld sec", perGuessTimeLimitSeconds),
                value: $perGuessTimeLimitSeconds,
                in: 5...180
            )
            .disabled(enablePerGuessTimeLimit == false)

            Toggle("Enable game time limit", isOn: $enableGameTimeLimit)
                .help(localized("help.settings.enable_game_time_limit"))
            Stepper(
                localized("Game limit: %lld sec", gameTimeLimitSeconds),
                value: $gameTimeLimitSeconds,
                in: 30...3600
            )
            .disabled(enableGameTimeLimit == false)
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tabItem {
            Label("Advanced", systemImage: "gearshape.2")
        }
    }

    private var soundTab: some View {
        Form {
            Toggle("Enable sound effects", isOn: $enableSoundEffects)
                .help(localized("help.settings.sound_effects"))

            HStack {
                Text("Volume")
                Slider(value: $soundEffectsVolume, in: 0...1, step: 0.05)
                    .disabled(enableSoundEffects == false)
                Text("\(Int(soundEffectsVolume * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
                    .foregroundStyle(enableSoundEffects ? .primary : .secondary)
            }
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tabItem {
            Label("Sound", systemImage: "speaker.wave.2")
        }
    }

    private var languageTab: some View {
        Form {
            Picker("App Language", selection: $appLanguageCode) {
                Text("Follow System").tag("system")
                Text("English").tag("en")
                Text("Magyar").tag("hu")
            }
            .pickerStyle(.radioGroup)
            .onChange(of: appLanguageCode) {
                guard appLanguageCode != previousLanguageCode else { return }
                previousLanguageCode = appLanguageCode
                showRestartPrompt = true
            }

            Text("Some language changes require restart.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tabItem {
            Label("Language", systemImage: "globe")
        }
    }

    private var musicTab: some View {
        Form {
            Toggle("Enable background music", isOn: $enableBackgroundMusic)

            Picker("Track", selection: $backgroundMusicTrackID) {
                ForEach(SoundPlayer.availableBackgroundTracks) { track in
                    Text(track.displayName).tag(track.id)
                }
            }
            .disabled(enableBackgroundMusic == false)

            HStack {
                Text("Volume")
                Slider(value: $backgroundMusicVolume, in: 0...1, step: 0.05)
                    .disabled(enableBackgroundMusic == false)
                Text("\(Int(backgroundMusicVolume * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
                    .foregroundStyle(enableBackgroundMusic ? .primary : .secondary)
            }
        }
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tabItem {
            Label("Music", systemImage: "music.note")
        }
    }

    private var themeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Animal Theme")
                    .font(.headline)

                ForEach(animalThemes) { theme in
                    themeRow(theme)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tabItem {
            Label("Theme", systemImage: "paintpalette")
        }
    }

    @ViewBuilder
    private func themeRow(_ theme: AnimalTheme) -> some View {
        let isSelected = selectedAnimalThemeID == theme.id

        HStack(spacing: 12) {
            Image(theme.bullAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Image(theme.cowAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
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
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            applyTheme(theme)
        }
    }
}

private struct AnimalTheme: Identifiable {
    let id: String
    let nameKey: String
    let bullAsset: String
    let cowAsset: String
}

#Preview {
    SettingsView()
}
