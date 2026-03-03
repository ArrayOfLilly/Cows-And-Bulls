//
//  SettingsView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 25..
//

import SwiftUI
import AppKit

/// Central settings UI for gameplay rules, audio, language, and visual themes.
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
    @AppStorage("selectedAnimalThemeID") private var selectedAnimalThemeID = "classic"
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"
    
    @State private var previousLanguageCode = "system"
    @State private var showRestartPrompt = false

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
        // TabView is used as a settings-page switcher.
        // This keeps each settings category isolated and easier to maintain.
        TabView {
            gameTab
            advancedTab
            soundTab
            musicTab
            languageTab
            themeTab
        }
            .frame(width: 420, height: 450)
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
        // confirmationDialog is more lightweight than a full modal sheet for one decision.
        .confirmationDialog(
            localized("Restart required"),
            isPresented: $showRestartPrompt,
            titleVisibility: .visible
        ) {
            Button(localized("Restart now"), role: .destructive) {
                restartApplication()
            }
            Button(localized("Later"), role: .cancel) { }
        } message: {
            Text(localized("Settings change may require app restart. Restart now?"))
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

    /// Persists the selected bull/cow asset pair as the active theme.
    private func applyTheme(_ theme: AnimalTheme) {
        selectedAnimalThemeID = theme.id
        selectedBullAssetName = theme.bullAsset
        selectedCowAssetName = theme.cowAsset
    }

    private func restartApplication() {
        // AppKit-only restart approach:
        // 1) reopen current app bundle URL
        // 2) terminate current process
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.open(appURL)
        NSApp.terminate(nil)
    }

    /// Pushes music-related settings to the audio service immediately.
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
                .padding(.bottom, 5)
            
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
                .padding(.bottom, 5)
            
            Toggle("Enable hard mode", isOn: $enableHardMode)
                .help(localized("help.settings.enable_hard_mode"))
                .padding(.bottom, 5)
            
            Toggle("Show guess count", isOn: $showGuessCount)
                .help(localized("help.settings.show_guess_count"))
                .padding(.bottom, 10)

            Divider()
                .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 5) {
                // MARK: - Per-guess time limit
                Toggle(localized("Enable per-guess time limit"), isOn: $enablePerGuessTimeLimit)
                    .help(localized("help.settings.enable_per_guess_time_limit"))
                    .padding(.bottom, 5)
                
                VStack {
                    Slider(
                        value: Binding(
                            get: { Double(perGuessTimeLimitSeconds) },
                            set: { perGuessTimeLimitSeconds = Int($0) }
                        ),
                        in: 5...180,
                        step: 5
                    )
                    .disabled(!enablePerGuessTimeLimit)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 5)
                    Text(localized("Per-guess limit: %lld sec", perGuessTimeLimitSeconds))
                        .font(.headline)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)

                // MARK: - Game time limit
                Toggle(localized("Enable game time limit"), isOn: $enableGameTimeLimit)
                    .help(localized("help.settings.enable_game_time_limit"))
                    .padding(.bottom, 5)
                
                VStack {
                    Slider(
                        value: Binding(
                            get: { Double(gameTimeLimitSeconds) },
                            set: { gameTimeLimitSeconds = Int($0) }
                        ),
                        in: 300...1800,
                        step: 60
                    )
                        .disabled(!enableGameTimeLimit)
                        .padding(.horizontal, 50)
                        .padding(.bottom, 5)
                    
                    Text(localized("Game limit: %lld sec", gameTimeLimitSeconds))
                        .font(.headline)
                }
                .padding(.horizontal, 10)
            }
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
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable sound effects", isOn: $enableSoundEffects)
                    .help(localized("help.settings.sound_effects"))

                HStack(spacing: 12) {
                    Text("Volume")
                    Slider(value: $soundEffectsVolume, in: 0...1, step: 0.05)
                        .disabled(enableSoundEffects == false)
                    Text("\(Int(soundEffectsVolume * 100))%")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                        .foregroundStyle(enableSoundEffects ? .primary : .secondary)
                }
            }
                .padding(.vertical, 6)
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
                    .padding(.bottom, 2)
                Text("English").tag("en")
                    .padding(.bottom, 2)
                Text("Magyar").tag("hu")
                    .padding(.bottom, 2)
            }
            // Radio group works well for small mutually exclusive sets.
            .pickerStyle(.radioGroup)
                .onChange(of: appLanguageCode) {
                guard appLanguageCode != previousLanguageCode else { return }
                previousLanguageCode = appLanguageCode
                showRestartPrompt = true
            }

            Text("Some language changes require restart.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 10)
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
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable background music", isOn: $enableBackgroundMusic)

                Picker("Track", selection: $backgroundMusicTrackID) {
                    ForEach(SoundPlayer.availableBackgroundTracks) { track in
                        Text(track.displayName).tag(track.id)
                    }
                }
                // Menu picker keeps this row compact even if track list grows.
                .disabled(enableBackgroundMusic == false)

                HStack(spacing: 12) {
                    Text("Volume")
                    Slider(value: $backgroundMusicVolume, in: 0...1, step: 0.05)
                        .disabled(enableBackgroundMusic == false)
                    Text("\(Int(backgroundMusicVolume * 100))%")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                        .foregroundStyle(enableBackgroundMusic ? .primary : .secondary)
                }
            }
                .padding(.vertical, 6)
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
        // contentShape makes the whole row tappable, not only the visible subviews.
        .contentShape(Rectangle())
        // onTapGesture keeps row selection behavior lightweight without a full Button style.
        .onTapGesture {
            applyTheme(theme)
        }
    }
}

/// Metadata model for one selectable visual theme pair.
private struct AnimalTheme: Identifiable {
    let id: String
    let nameKey: String
    let bullAsset: String
    let cowAsset: String
}

#Preview {
    SettingsView()
}
