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
    private enum SettingsTab: Hashable {
        case game
        case advanced
        case sound
        case music
        case profiles
        case language
        case theme
    }

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
    @State private var profileEditorState = ProfileEditorState()
    @State private var profilePendingDelete: PlayerProfile?
    @State private var answerLengthDraft = ""
    @State private var selectedTab: SettingsTab = .game

    @FocusState private var isAnswerLengthFocused: Bool

    private let animalThemes = AnimalTheme.all

    private var showsUITestTabShortcuts: Bool {
        ProcessInfo.processInfo.environment["UITEST_SETTINGS_TAB_SHORTCUTS"] == "1"
    }

    private var canEditGameplaySettings: Bool {
        gameSessionStore.canEditGameplaySettings
    }

    private var gameInProgress: Bool {
        gameSessionStore.gameInProgress
    }

    private var settings: ProfileSettings { settingsStore.settings }
    
    private var canCreateProfiles: Bool { gameInProgress == false }
    
    private var canRenameProfiles: Bool { gameInProgress == false }
    
    private var canReorderProfiles: Bool { gameInProgress == false }
    
    private var canDeleteProfiles: Bool { gameInProgress == false && profileStore.profiles.count > 1 }
    
    private var answerLengthHasValidationError: Bool {
        guard let draftValue = Int(answerLengthDraft) else { return false }
        return draftValue < 3 || draftValue > 8
    }
    
    private var selectedTheme: AnimalTheme? {
        animalThemes.first { $0.id == settings.selectedAnimalThemeID }
    }

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
        TabView(selection: $selectedTab) {
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
            .overlay(alignment: .topTrailing) {
                if showsUITestTabShortcuts {
                    HStack(spacing: 6) {
                        settingsUITestTabButton(id: "settingsOpenGameTab", tab: .game)
                        settingsUITestTabButton(id: "settingsOpenSoundTab", tab: .sound)
                        settingsUITestTabButton(id: "settingsOpenProfilesTab", tab: .profiles)
                        settingsUITestTabButton(id: "settingsOpenLanguageTab", tab: .language)
                        settingsUITestTabButton(id: "settingsOpenThemeTab", tab: .theme)
                    }
                    .padding(8)
                }
            }
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

    private func settingsUITestTabButton(id: String, tab: SettingsTab) -> some View {
        Button(id) {
            selectedTab = tab
        }
        .font(.caption2)
        .accessibilityIdentifier(id)
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
                profileEditorState.draftName(for: profile)
            },
            set: { newValue in
                profileEditorState.setDraftName(newValue, for: profile)
            }
        )
    }

    private func commitProfileName(_ profile: PlayerProfile) {
        let draft = profileEditorState.draftName(for: profile)
        profileStore.renameProfile(id: profile.id, name: draft)
        if let updated = profileStore.profiles.first(where: { $0.id == profile.id }) {
            profileEditorState.setDraftName(updated.name, for: updated)
        }
    }

    private func profileHelpText(defaultKey: String, disabledKey: String, isDisabled: Bool) -> String {
        isDisabled ? localized(disabledKey) : localized(defaultKey)
    }

    private func profileRowState(for profile: PlayerProfile) -> ProfileRowState {
        let canMakeActive = profile.id != profileStore.selectedProfileId
        let canMoveUp = isFirstProfile(profile) == false
        let canMoveDown = isLastProfile(profile) == false

        let makeActiveHelpText: String
        if canRenameProfiles == false {
            makeActiveHelpText = localized("profiles.disabled.during_game")
        } else if canMakeActive == false {
            makeActiveHelpText = localized("profiles.make_active.disabled.already")
        } else {
            makeActiveHelpText = localized("profiles.make_active.help")
        }

        let moveUpHelpText: String
        if canReorderProfiles == false {
            moveUpHelpText = localized("profiles.disabled.during_game")
        } else if canMoveUp == false {
            moveUpHelpText = localized("profiles.reorder.disabled.top")
        } else {
            moveUpHelpText = localized("profiles.reorder.up")
        }

        let moveDownHelpText: String
        if canReorderProfiles == false {
            moveDownHelpText = localized("profiles.disabled.during_game")
        } else if canMoveDown == false {
            moveDownHelpText = localized("profiles.reorder.disabled.bottom")
        } else {
            moveDownHelpText = localized("profiles.reorder.down")
        }

        let deleteHelpText: String
        if gameInProgress {
            deleteHelpText = localized("profiles.disabled.during_game")
        } else if canDeleteProfiles == false {
            deleteHelpText = localized("profiles.delete.disabled.single")
        } else {
            deleteHelpText = localized("profiles.delete.help")
        }

        return ProfileRowState(
            canMakeActive: canMakeActive,
            canMoveUp: canMoveUp,
            canMoveDown: canMoveDown,
            canDeleteProfiles: canDeleteProfiles,
            makeActiveHelpText: makeActiveHelpText,
            moveUpHelpText: moveUpHelpText,
            moveDownHelpText: moveDownHelpText,
            deleteHelpText: deleteHelpText
        )
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
                canEditSettings: canEditGameplaySettings,
                answerLengthFocus: $isAnswerLengthFocused,
                showAnswerLengthError: answerLengthHasValidationError,
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
        .tag(SettingsTab.game)
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
                canEditSettings: canEditGameplaySettings,
                gameInProgress: gameInProgress
            )
        }
        .tag(SettingsTab.advanced)
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
        .tag(SettingsTab.sound)
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
        .tag(SettingsTab.language)
        .tabItem {
            Label("Language", systemImage: "globe")
        }
    }

    private var profilesTab: some View {
        SettingsProfilesTab(
            profiles: profileStore.profiles,
            selectedProfileID: profileStore.selectedProfileId,
            newProfileName: $profileEditorState.newProfileName,
            canEditSettings: canRenameProfiles,
            draftBindingForProfileName: draftBindingForProfileName,
            onCreateProfile: {
                profileStore.createProfile(named: profileEditorState.newProfileName)
                profileEditorState.newProfileName = ""
            },
            onBeginEditing: { profile in
                profileEditorState.beginEditing(profile)
            },
            onEndEditing: { profile in
                profileEditorState.endEditing(profile)
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
                isDisabled: canCreateProfiles == false
            ),
            editProfileHelpText: profileHelpText(
                defaultKey: "profiles.name.help",
                disabledKey: "profiles.disabled.during_game",
                isDisabled: canRenameProfiles == false
            ),
            profileRowState: profileRowState
        )
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: profileStore.profiles) { _, newProfiles in
            profileEditorState.syncDrafts(with: newProfiles)
        }
        .accessibilityIdentifier("settingsProfilesTabContent")
        .overlay(alignment: .bottomTrailing) {
            if showsUITestTabShortcuts {
                Text(canRenameProfiles ? "editable" : "locked")
                    .font(.caption2)
                    .accessibilityIdentifier("settingsProfilesEditabilityState")
                    .accessibilityValue(canRenameProfiles ? "editable" : "locked")
                    .padding(8)
            }
        }
        .tag(SettingsTab.profiles)
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
        .tag(SettingsTab.music)
        .tabItem {
            Label(localized("settings.tab.music"), systemImage: "music.note")
        }
    }
    private var themeTab: some View {
        SettingsThemeTab(
            animalThemes: animalThemes,
            selectedThemeID: selectedTheme?.id ?? settings.selectedAnimalThemeID,
            onSelectTheme: applyTheme
        )
        .tag(SettingsTab.theme)
        .tabItem {
            Label("Theme", systemImage: "paintpalette")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProfileStore())
        .environmentObject(HistoryStore())
        .environmentObject(ProfileSettingsStore())
}
