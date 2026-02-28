//
//  SettingsView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 25..
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("maximumGuesses") private var maximumGuesses = 10
    @AppStorage("answerLength") private var answerLength = 4
    @AppStorage("enableRepeats") private var enableRepeats = false
    @AppStorage("enableHardMode") private var enableHardMode = false
    @AppStorage("showGuessCount") private var showGuessCount = false
    @AppStorage("enableSoundEffects") private var enableSoundEffects = true
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume = 0.8
    @AppStorage("appLanguageCode") private var appLanguageCode = "system"

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
            languageTab
            themeTab
        }
        .frame(width: 420, height: 400)
        .onAppear {
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
    }

    private func applyTheme(_ theme: AnimalTheme) {
        selectedAnimalThemeID = theme.id
        selectedBullAssetName = theme.bullAsset
        selectedCowAssetName = theme.cowAsset
    }

    private var gameTab: some View {
        Form {
            TextField("Maximum guesses:", value: $maximumGuesses, format: .number)
                .help("The maximum number of answers you can submit. Changing this will immediately restart your game.")

            TextField("Answer length:", value: $answerLength, format: .number)
                .help("The length of the number string to guess. Changing this will immediately restart your game.")

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
                .help("This enables repeating digits in the answer.")
            Toggle("Enable hard mode", isOn: $enableHardMode)
                .help("This shows the cows and bulls score for only the most recent guess.")
            Toggle("Show guess count", isOn: $showGuessCount)
                .help("Adds a footer below your guesses showing the total.")
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
                .help("Play submit, win, and lose sounds during gameplay.")

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

            Text("Changes apply immediately.")
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
