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
    @AppStorage("enableBackgroundMusic") private var enableBackgroundMusic = false
    @AppStorage("backgroundMusicTrackID") private var backgroundMusicTrackID = "Mushroom Background Music"
    @AppStorage("backgroundMusicVolume") private var backgroundMusicVolume = 0.35
    @AppStorage("appLanguageCode") private var appLanguageCode = "system"

    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var settingsStore: ProfileSettingsStore
    @EnvironmentObject private var gameSessionStore: GameSessionStore
    
    @State private var previousLanguageCode = "system"
    @State private var showRestartPrompt = false
    @State private var newProfileName = ""
    @State private var profilePendingDelete: PlayerProfile?
    @State private var profileNameDrafts: [String: String] = [:]
    @State private var editingProfileIds: Set<String> = []
    @State private var answerLengthDraft = ""

    @FocusState private var isAnswerLengthFocused: Bool

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

    private var canEditSettings: Bool {
        gameSessionStore.canEditGameplaySettings
    }

    private var gameInProgress: Bool {
        gameSessionStore.gameInProgress
    }

    private var settings: ProfileSettings { settingsStore.settings }

    private func binding<T>(_ keyPath: WritableKeyPath<ProfileSettings, T>) -> Binding<T> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                var updated = settingsStore.settings
                updated[keyPath: keyPath] = newValue
                settingsStore.settings = updated
            }
        )
    }

    var body: some View {
        // TabView is used as a settings-page switcher.
        // This keeps each settings category isolated and easier to maintain.
        TabView {
            gameTab
            advancedTab
            soundTab
            musicTab
            profilesTab
            languageTab
            themeTab
        }
            .accessibilityIdentifier("settingsRoot")
            .frame(minWidth: 440, minHeight: 480)
            .onAppear {
            previousLanguageCode = appLanguageCode
            if animalThemes.contains(where: { $0.id == settings.selectedAnimalThemeID }) == false {
                if let matchedTheme = animalThemes.first(where: {
                    $0.bullAsset == settings.selectedBullAssetName && $0.cowAsset == settings.selectedCowAssetName
                }) {
                    var updated = settingsStore.settings
                    updated.selectedAnimalThemeID = matchedTheme.id
                    settingsStore.settings = updated
                } else if let firstTheme = animalThemes.first {
                    applyTheme(firstTheme)
                }
            }
        }
        // confirmationDialog is more lightweight than a full modal sheet for one decision.
        .onAppear {
            if answerLengthDraft.isEmpty {
                answerLengthDraft = String(settings.answerLength)
            }
        }
        .onChange(of: settings.answerLength) { newValue, _ in
            if isAnswerLengthFocused == false {
                answerLengthDraft = String(newValue)
            }
        }
        .confirmationDialog(
            localized("settings.restart.title"),
            isPresented: $showRestartPrompt,
            titleVisibility: .visible
        ) {
            Button(localized("settings.restart.action_now"), role: .destructive) {
                restartApplication()
            }
            Button(localized("settings.restart.action_later"), role: .cancel) { }
        } message: {
            Text(localized("settings.restart.message"))
        }
        .confirmationDialog(
            localized("profiles.delete.title"),
            isPresented: Binding(
                get: { profilePendingDelete != nil },
                set: { if $0 == false { profilePendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(localized("profiles.delete.action"), role: .destructive) {
                if let profile = profilePendingDelete {
                    historyStore.deleteProfileData(profileId: profile.id)
                    settingsStore.deleteProfileData(profileId: profile.id)
                    profileStore.deleteProfile(id: profile.id)
                }
                profilePendingDelete = nil
            }
            Button(localized("common.action.cancel"), role: .cancel) {
                profilePendingDelete = nil
            }
        } message: {
            let name = profilePendingDelete?.name ?? ""
            Text(localized("profiles.delete.message", name))
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
        var updated = settingsStore.settings
        updated.selectedAnimalThemeID = theme.id
        updated.selectedBullAssetName = theme.bullAsset
        updated.selectedCowAssetName = theme.cowAsset
        settingsStore.settings = updated
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

    private func draftBindingForProfileName(_ profile: PlayerProfile) -> Binding<String> {
        Binding(
            get: {
                profileNameDrafts[profile.id] ?? profile.name
            },
            set: { newValue in
                profileNameDrafts[profile.id] = newValue
            }
        )
    }

    private func commitProfileName(_ profile: PlayerProfile) {
        let draft = profileNameDrafts[profile.id] ?? profile.name
        profileStore.renameProfile(id: profile.id, name: draft)
        if let updated = profileStore.profiles.first(where: { $0.id == profile.id }) {
            profileNameDrafts[profile.id] = updated.name
        }
    }

    private func profileHelpText(defaultKey: String, disabledKey: String, isDisabled: Bool) -> String {
        isDisabled ? localized(disabledKey) : localized(defaultKey)
    }

    private func makeActiveHelp(for profile: PlayerProfile) -> String {
        if gameInProgress {
            return localized("profiles.disabled.during_game")
        }
        if profile.id == profileStore.selectedProfileId {
            return localized("profiles.make_active.disabled.already")
        }
        return localized("profiles.make_active.help")
    }

    private func updateAnswerLength(_ value: Int) {
        var updated = settingsStore.settings
        updated.answerLength = value
        settingsStore.settings = updated
    }

    private func finalizeAnswerLengthDraft() {
        if let value = Int(answerLengthDraft), (3...8).contains(value) {
            updateAnswerLength(value)
        } else {
            answerLengthDraft = String(settings.answerLength)
        }
    }

    private func moveUpHelp(for profile: PlayerProfile) -> String {
        if gameInProgress {
            return localized("profiles.disabled.during_game")
        }
        if isFirstProfile(profile) {
            return localized("profiles.reorder.disabled.top")
        }
        return localized("profiles.reorder.up")
    }

    private func moveDownHelp(for profile: PlayerProfile) -> String {
        if gameInProgress {
            return localized("profiles.disabled.during_game")
        }
        if isLastProfile(profile) {
            return localized("profiles.reorder.disabled.bottom")
        }
        return localized("profiles.reorder.down")
    }

    private func deleteHelp(for profile: PlayerProfile) -> String {
        if gameInProgress {
            return localized("profiles.disabled.during_game")
        }
        if profileStore.profiles.count <= 1 {
            return localized("profiles.delete.disabled.single")
        }
        return localized("profiles.delete.help")
    }

    private func isFirstProfile(_ profile: PlayerProfile) -> Bool {
        profileStore.profiles.first?.id == profile.id
    }

    private func isLastProfile(_ profile: PlayerProfile) -> Bool {
        profileStore.profiles.last?.id == profile.id
    }

    private var gameTab: some View {
        SettingsFormContainer {
            SettingsGameTab(
                maximumGuesses: binding(\.maximumGuesses),
                answerLengthDraft: $answerLengthDraft,
                enableCelebration: binding(\.enableCelebration),
                canEditSettings: canEditSettings,
                answerLengthFocus: $isAnswerLengthFocused,
                showAnswerLengthError: {
                    if let draftValue = Int(answerLengthDraft) {
                        return draftValue < 3 || draftValue > 8
                    }
                    return false
                }(),
                onAnswerLengthChange: { newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue {
                        answerLengthDraft = digits
                        return
                    }
                    guard let value = Int(digits), (3...8).contains(value) else { return }
                    updateAnswerLength(value)
                },
                onFinalizeAnswerLength: finalizeAnswerLengthDraft
            )
        }
        .navigationTitle("Settings")
        .tabItem {
            Label("Game", image: "Cow")
        }
    }

    private var advancedTab: some View {
        SettingsFormContainer {
            SettingsAdvancedTab(
                enableRepeats: binding(\.enableRepeats),
                enableHardMode: binding(\.enableHardMode),
                showGuessCount: binding(\.showGuessCount),
                enablePerGuessTimeLimit: binding(\.enablePerGuessTimeLimit),
                perGuessTimeLimitSeconds: Binding(
                    get: { Double(settings.perGuessTimeLimitSeconds) },
                    set: { newValue in
                        var updated = settingsStore.settings
                        updated.perGuessTimeLimitSeconds = Int(newValue)
                        settingsStore.settings = updated
                    }
                ),
                perGuessTimeLimitValue: settings.perGuessTimeLimitSeconds,
                enableGameTimeLimit: binding(\.enableGameTimeLimit),
                gameTimeLimitSeconds: Binding(
                    get: { Double(settings.gameTimeLimitSeconds) },
                    set: { newValue in
                        var updated = settingsStore.settings
                        updated.gameTimeLimitSeconds = Int(newValue)
                        settingsStore.settings = updated
                    }
                ),
                gameTimeLimitValue: settings.gameTimeLimitSeconds,
                canEditSettings: canEditSettings,
                gameInProgress: gameInProgress
            )
        }
        .tabItem {
            Label("Advanced", systemImage: "gearshape.2")
        }
    }

    private var soundTab: some View {
        SettingsFormContainer {
            SettingsSoundTab(
                enableSoundEffects: binding(\.enableSoundEffects),
                soundEffectsVolume: binding(\.soundEffectsVolume),
                soundEffectsVolumeValue: settings.soundEffectsVolume
            )
        }
        .tabItem {
            Label("Sound", systemImage: "speaker.wave.2")
        }
    }

    private var languageTab: some View {
        SettingsFormContainer {
            SettingsLanguageTab(appLanguageCode: $appLanguageCode)
                .onChange(of: appLanguageCode) {
                    guard appLanguageCode != previousLanguageCode else { return }
                    previousLanguageCode = appLanguageCode
                    showRestartPrompt = true
                }
        }
        .tabItem {
            Label("Language", systemImage: "globe")
        }
    }

    private var profilesTab: some View {
        SettingsProfilesTab(
            profiles: profileStore.profiles,
            selectedProfileID: profileStore.selectedProfileId,
            newProfileName: $newProfileName,
            canEditSettings: canEditSettings,
            draftBindingForProfileName: draftBindingForProfileName,
            onCreateProfile: {
                profileStore.createProfile(named: newProfileName)
                newProfileName = ""
            },
            onBeginEditing: { profile in
                editingProfileIds.insert(profile.id)
            },
            onEndEditing: { profile in
                editingProfileIds.remove(profile.id)
                commitProfileName(profile)
            },
            onCommitProfileName: commitProfileName,
            onMakeActive: { profile in
                profileStore.selectProfile(id: profile.id)
            },
            onMoveUp: { profile in
                profileStore.moveProfile(id: profile.id, direction: -1)
            },
            onMoveDown: { profile in
                profileStore.moveProfile(id: profile.id, direction: 1)
            },
            onDelete: { profile in
                profilePendingDelete = profile
            },
            createProfileHelpText: profileHelpText(
                defaultKey: "profiles.new.help",
                disabledKey: "profiles.disabled.during_game",
                isDisabled: canEditSettings == false
            ),
            editProfileHelpText: profileHelpText(
                defaultKey: "profiles.name.help",
                disabledKey: "profiles.disabled.during_game",
                isDisabled: canEditSettings == false
            ),
            makeActiveHelp: makeActiveHelp,
            moveUpHelp: moveUpHelp,
            moveDownHelp: moveDownHelp,
            deleteHelp: deleteHelp,
            isFirstProfile: isFirstProfile,
            isLastProfile: isLastProfile
        )
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: profileStore.profiles) { _, newProfiles in
            for profile in newProfiles where editingProfileIds.contains(profile.id) == false {
                profileNameDrafts[profile.id] = profile.name
            }
        }
        .tabItem {
            Label(localized("settings.tab.profiles"), systemImage: "person.2")
        }
    }

    private var musicTab: some View {
        SettingsFormContainer {
            SettingsMusicTab(
                enableBackgroundMusic: $enableBackgroundMusic,
                backgroundMusicTrackID: $backgroundMusicTrackID,
                backgroundMusicVolume: $backgroundMusicVolume
            )
        }
        .tabItem {
            Label(localized("settings.tab.music"), systemImage: "music.note")
        }
    }
    private var themeTab: some View {
        SettingsThemeTab(
            animalThemes: animalThemes,
            selectedThemeID: settings.selectedAnimalThemeID,
            onSelectTheme: applyTheme
        )
        .tabItem {
            Label("Theme", systemImage: "paintpalette")
        }
    }
}

private struct SettingsFormContainer<Content: View>: View {
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

private struct SettingsGameTab: View {
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
            .padding(.top, 8)
    }
}

private struct SettingsAdvancedTab: View {
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
        Toggle("Enable repeating", isOn: enableRepeats)
            .help(localized("help.settings.enable_repeating"))
            .disabled(canEditSettings == false)
            .padding(.bottom, 5)

        Toggle("Enable hard mode", isOn: enableHardMode)
            .help(localized("help.settings.enable_hard_mode"))
            .disabled(canEditSettings == false)
            .padding(.bottom, 5)

        Toggle("Show guess count", isOn: showGuessCount)
            .help(localized("help.settings.show_guess_count"))
            .disabled(canEditSettings == false)
            .padding(.bottom, 10)

        Divider()
            .padding(.vertical, 20)

        VStack(alignment: .leading, spacing: 5) {
            Toggle(localized("settings.timer.per_guess.enable"), isOn: enablePerGuessTimeLimit)
                .help(localized("help.settings.enable_per_guess_time_limit"))
                .disabled(canEditSettings == false)
                .padding(.bottom, 5)

            VStack {
                Slider(value: perGuessTimeLimitSeconds, in: 5...180, step: 5)
                    .disabled(enablePerGuessTimeLimit.wrappedValue == false || canEditSettings == false)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 5)
                Text(localized("settings.timer.per_guess.value", perGuessTimeLimitValue))
                    .font(.headline)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)

            Toggle(localized("settings.timer.game.enable"), isOn: enableGameTimeLimit)
                .help(localized("help.settings.enable_game_time_limit"))
                .disabled(canEditSettings == false)
                .padding(.bottom, 5)

            VStack {
                Slider(value: gameTimeLimitSeconds, in: 300...1800, step: 60)
                    .disabled(enableGameTimeLimit.wrappedValue == false || canEditSettings == false)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 5)

                Text(localized("settings.timer.game.value", gameTimeLimitValue))
                    .font(.headline)
            }
            .padding(.horizontal, 10)

            if gameInProgress {
                Text(localized("settings.warning.timer_locked_during_game"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }
}

private struct SettingsSoundTab: View {
    let enableSoundEffects: Binding<Bool>
    let soundEffectsVolume: Binding<Double>
    let soundEffectsVolumeValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable sound effects", isOn: enableSoundEffects)
                .help(localized("help.settings.sound_effects"))

            HStack(spacing: 12) {
                Text("Volume")
                Slider(value: soundEffectsVolume, in: 0...1, step: 0.05)
                    .disabled(enableSoundEffects.wrappedValue == false)
                Text("\(Int(soundEffectsVolumeValue * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
                    .foregroundStyle(enableSoundEffects.wrappedValue ? .primary : .secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SettingsLanguageTab: View {
    let appLanguageCode: Binding<String>

    var body: some View {
        Picker("App Language", selection: appLanguageCode) {
            Text("Follow System").tag("system")
                .padding(.bottom, 2)
            Text("English").tag("en")
                .padding(.bottom, 2)
            Text("Magyar").tag("hu")
                .padding(.bottom, 2)
        }
        .pickerStyle(.radioGroup)

        Text("Some language changes require restart.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 10)
    }
}

private struct SettingsMusicTab: View {
    let enableBackgroundMusic: Binding<Bool>
    let backgroundMusicTrackID: Binding<String>
    let backgroundMusicVolume: Binding<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(localized("settings.music.enable"), isOn: enableBackgroundMusic)

            Picker(localized("settings.music.track"), selection: backgroundMusicTrackID) {
                ForEach(SoundPlayer.availableBackgroundTracks) { track in
                    Text(track.displayName).tag(track.id)
                }
            }
            .disabled(enableBackgroundMusic.wrappedValue == false)

            HStack(spacing: 12) {
                Text("Volume")
                Slider(value: backgroundMusicVolume, in: 0...1, step: 0.05)
                    .disabled(enableBackgroundMusic.wrappedValue == false)
                Text("\(Int(backgroundMusicVolume.wrappedValue * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
                    .foregroundStyle(enableBackgroundMusic.wrappedValue ? .primary : .secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct SettingsThemeTab: View {
    let animalThemes: [AnimalTheme]
    let selectedThemeID: String
    let onSelectTheme: (AnimalTheme) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Animal Theme")
                    .font(.headline)

                ForEach(animalThemes) { theme in
                    ThemeRowView(
                        theme: theme,
                        isSelected: selectedThemeID == theme.id,
                        onSelect: {
                            onSelectTheme(theme)
                        }
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct ThemeRowView: View {
    let theme: AnimalTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(theme.bullAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .animalIconStyle(cornerRadius: 6)

            Image(theme.cowAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(.trailing, 10)
                .animalIconStyle(cornerRadius: 6)

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
        .onTapGesture(perform: onSelect)
    }
}

private struct SettingsProfilesTab: View {
    let profiles: [PlayerProfile]
    let selectedProfileID: String
    let newProfileName: Binding<String>
    let canEditSettings: Bool
    let draftBindingForProfileName: (PlayerProfile) -> Binding<String>
    let onCreateProfile: () -> Void
    let onBeginEditing: (PlayerProfile) -> Void
    let onEndEditing: (PlayerProfile) -> Void
    let onCommitProfileName: (PlayerProfile) -> Void
    let onMakeActive: (PlayerProfile) -> Void
    let onMoveUp: (PlayerProfile) -> Void
    let onMoveDown: (PlayerProfile) -> Void
    let onDelete: (PlayerProfile) -> Void
    let createProfileHelpText: String
    let editProfileHelpText: String
    let makeActiveHelp: (PlayerProfile) -> String
    let moveUpHelp: (PlayerProfile) -> String
    let moveDownHelp: (PlayerProfile) -> String
    let deleteHelp: (PlayerProfile) -> String
    let isFirstProfile: (PlayerProfile) -> Bool
    let isLastProfile: (PlayerProfile) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfilesToolbarRow(
                newProfileName: newProfileName,
                canEditSettings: canEditSettings,
                createProfileHelpText: createProfileHelpText,
                onCreateProfile: onCreateProfile
            )

            List {
                ForEach(profiles) { profile in
                    ProfileRowView(
                        profile: profile,
                        isSelected: profile.id == selectedProfileID,
                        nameBinding: draftBindingForProfileName(profile),
                        canEditSettings: canEditSettings,
                        canDeleteProfiles: profiles.count > 1,
                        canMakeActive: profile.id != selectedProfileID,
                        canMoveUp: isFirstProfile(profile) == false,
                        canMoveDown: isLastProfile(profile) == false,
                        editProfileHelpText: editProfileHelpText,
                        makeActiveHelpText: makeActiveHelp(profile),
                        moveUpHelpText: moveUpHelp(profile),
                        moveDownHelpText: moveDownHelp(profile),
                        deleteHelpText: deleteHelp(profile),
                        onBeginEditing: { onBeginEditing(profile) },
                        onEndEditing: { onEndEditing(profile) },
                        onCommitProfileName: { onCommitProfileName(profile) },
                        onMakeActive: { onMakeActive(profile) },
                        onMoveUp: { onMoveUp(profile) },
                        onMoveDown: { onMoveDown(profile) },
                        onDelete: { onDelete(profile) }
                    )
                }
            }
        }
    }
}

private struct ProfilesToolbarRow: View {
    let newProfileName: Binding<String>
    let canEditSettings: Bool
    let createProfileHelpText: String
    let onCreateProfile: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField(localized("profiles.new.placeholder"), text: newProfileName)
                .textFieldStyle(.roundedBorder)
                .disabled(canEditSettings == false)
                .help(createProfileHelpText)
                .accessibilityIdentifier("profilesNewNameField")

            Button(localized("profiles.new.action"), action: onCreateProfile)
                .disabled(canEditSettings == false)
                .help(createProfileHelpText)
                .accessibilityIdentifier("profilesCreateButton")

            Spacer()

            Text(localized("profiles.reorder.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProfileRowView: View {
    let profile: PlayerProfile
    let isSelected: Bool
    let nameBinding: Binding<String>
    let canEditSettings: Bool
    let canDeleteProfiles: Bool
    let canMakeActive: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let editProfileHelpText: String
    let makeActiveHelpText: String
    let moveUpHelpText: String
    let moveDownHelpText: String
    let deleteHelpText: String
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void
    let onCommitProfileName: () -> Void
    let onMakeActive: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help(localized("profiles.active.help"))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }

            TextField(
                localized("profiles.name.placeholder"),
                text: nameBinding,
                onEditingChanged: { isEditing in
                    if isEditing {
                        onBeginEditing()
                    } else {
                        onEndEditing()
                    }
                },
                onCommit: onCommitProfileName
            )
            .textFieldStyle(.plain)
            .disabled(canEditSettings == false)
            .help(editProfileHelpText)

            Spacer()

            ProfileActionButtons(
                canEditSettings: canEditSettings,
                canDeleteProfiles: canDeleteProfiles,
                canMakeActive: canMakeActive,
                canMoveUp: canMoveUp,
                canMoveDown: canMoveDown,
                makeActiveHelpText: makeActiveHelpText,
                moveUpHelpText: moveUpHelpText,
                moveDownHelpText: moveDownHelpText,
                deleteHelpText: deleteHelpText,
                onMakeActive: onMakeActive,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onDelete: onDelete
            )
        }
    }
}

private struct ProfileActionButtons: View {
    let canEditSettings: Bool
    let canDeleteProfiles: Bool
    let canMakeActive: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let makeActiveHelpText: String
    let moveUpHelpText: String
    let moveDownHelpText: String
    let deleteHelpText: String
    let onMakeActive: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(localized("profiles.make_active"), action: onMakeActive)
            .disabled(canEditSettings == false || canMakeActive == false)
            .help(makeActiveHelpText)

        Button(action: onMoveUp) {
            Image(systemName: "chevron.up")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(canEditSettings == false || canMoveUp == false)
        .help(moveUpHelpText)

        Button(action: onMoveDown) {
            Image(systemName: "chevron.down")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(canEditSettings == false || canMoveDown == false)
        .help(moveDownHelpText)

        Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(deleteHelpText)
        .disabled(canEditSettings == false || canDeleteProfiles == false)
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
        .environmentObject(ProfileStore())
        .environmentObject(HistoryStore())
        .environmentObject(ProfileSettingsStore())
}
