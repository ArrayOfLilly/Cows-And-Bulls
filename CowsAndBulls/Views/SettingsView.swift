//
//  SettingsView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 25..
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
    @State private var backupDocument: AppBackupDocument?
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var backupStatusMessage: String?

    @FocusState private var isAnswerLengthFocused: Bool

    private let animalThemes = AnimalTheme.all

    private var showsUITestTabShortcuts: Bool {
        ProcessInfo.processInfo.environment["UITEST_SETTINGS_TAB_SHORTCUTS"] == "1"
    }

    private var initialUITestTab: SettingsTab? {
        guard let value = ProcessInfo.processInfo.environment["UITEST_SETTINGS_INITIAL_TAB"] else {
            return nil
        }

        switch value {
        case "game":
            return .game
        case "advanced":
            return .advanced
        case "sound":
            return .sound
        case "music":
            return .music
        case "profiles":
            return .profiles
        case "language":
            return .language
        case "theme":
            return .theme
        default:
            return nil
        }
    }

    private var canEditGameplaySettings: Bool {
        gameSessionStore.canEditGameplaySettings
    }

    private var gameInProgress: Bool {
        gameSessionStore.gameInProgress
    }

    private var settings: ProfileSettings { settingsStore.settings }
    private var profileRules: ProfileSettingsRules {
        ProfileSettingsRules(
            profiles: profileStore.profiles,
            selectedProfileID: profileStore.selectedProfileId,
            gameInProgress: gameInProgress
        )
    }

    private var canCreateProfiles: Bool { profileRules.canCreateProfiles }
    private var canRenameProfiles: Bool { profileRules.canRenameProfiles }
    private var canReorderProfiles: Bool { profileRules.canReorderProfiles }
    private var canDeleteProfiles: Bool { profileRules.canDeleteProfiles }
    
    private var answerLengthHasValidationError: Bool {
        guard let draftValue = Int(answerLengthDraft) else { return false }
        return draftValue < 3 || draftValue > 8
    }
    
    private var selectedTheme: AnimalTheme? {
        animalThemes.first { $0.id == settings.selectedAnimalThemeID }
    }

    private var backupController: AppBackupController {
        AppBackupController(
            profileStore: profileStore,
            settingsStore: settingsStore,
            historyStore: historyStore,
            gameSessionStore: gameSessionStore
        )
    }

    private var appPreferencesSnapshot: AppPreferencesSnapshot {
        AppPreferencesSnapshot(
            appLanguageCode: appLanguageCode,
            enableBackgroundMusic: enableBackgroundMusic,
            backgroundMusicTrackID: backgroundMusicTrackID,
            backgroundMusicVolume: backgroundMusicVolume
        )
    }

    private var appVersionDescription: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(shortVersion) (\(buildVersion))"
    }

    private func profilesReorderState(for index: Int) -> String? {
        guard profileStore.profiles.indices.contains(index) else { return nil }
        let rowState = profileRules.rowState(for: profileStore.profiles[index])
        let moveUpState = rowState.canMoveUp ? "enabled" : "disabled"
        let moveDownState = rowState.canMoveDown ? "enabled" : "disabled"
        return "up:\(moveUpState),down:\(moveDownState)"
    }

    private var profilesEditabilityAccessibilityValue: String {
        let editability = canRenameProfiles ? "editable" : "locked"
        let reorderSummary = (0..<3)
            .compactMap { index in
                profilesReorderState(for: index).map { "row\(index):\($0)" }
            }
            .joined(separator: "|")

        guard reorderSummary.isEmpty == false else { return editability }
        return "\(editability)|\(reorderSummary)"
    }

    private var profilesOrderAccessibilityValue: String {
        profileStore.profiles
            .map(\.name)
            .joined(separator: "|")
    }

    private var selectedThemeAccessibilityValue: String {
        settings.selectedAnimalThemeID
    }

    private var profilesUITestStateValue: String {
        "\(profilesEditabilityAccessibilityValue)||order:\(profilesOrderAccessibilityValue)"
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
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 6) {
                            settingsUITestTabButton(id: "settingsOpenGameTab", tab: .game)
                            settingsUITestTabButton(id: "settingsOpenSoundTab", tab: .sound)
                            settingsUITestTabButton(id: "settingsOpenProfilesTab", tab: .profiles)
                            settingsUITestTabButton(id: "settingsOpenLanguageTab", tab: .language)
                            settingsUITestTabButton(id: "settingsOpenThemeTab", tab: .theme)
                        }
                        Text(selectedTabAccessibilityValue)
                            .font(.caption2)
                            .accessibilityIdentifier("settingsSelectedTabState")
                            .accessibilityValue(selectedTabAccessibilityValue)

                        settingsUITestHooks
                    }
                    .padding(8)
                }
            }
        .onAppear {
            previousLanguageCode = appLanguageCode
            if let initialUITestTab {
                selectedTab = initialUITestTab
            }
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
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "cows-and-bulls-backup"
        ) { result in
            switch result {
            case .success:
                backupStatusMessage = "Backup exported successfully."
            case .failure(let error):
                backupStatusMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.json]
        ) { result in
            handleImportResult(result)
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

    private var selectedTabAccessibilityValue: String {
        switch selectedTab {
        case .game: "game"
        case .advanced: "advanced"
        case .sound: "sound"
        case .music: "music"
        case .profiles: "profiles"
        case .language: "language"
        case .theme: "theme"
        }
    }

    @ViewBuilder
    private var settingsUITestHooks: some View {
        Text("seedProfiles")
            .contentShape(Rectangle())
            .onTapGesture {
                profileStore.replaceProfilesForUITesting(
                    names: ["UI Reorder Alpha", "UI Reorder Bravo", "UI Reorder Charlie"]
                )
            }
            .font(.caption2)
            .accessibilityIdentifier("settingsSeedProfilesForReorderTest")

        Text("moveSecondProfileUp")
            .contentShape(Rectangle())
            .onTapGesture {
                guard profileStore.profiles.indices.contains(1) else { return }
                let profile = profileStore.profiles[1]
                profileStore.moveProfile(id: profile.id, direction: -1)
            }
            .font(.caption2)
            .accessibilityIdentifier("settingsMoveSecondProfileUpForTest")

        Text(canRenameProfiles ? "editable" : "locked")
            .font(.caption2)
            .accessibilityIdentifier("settingsProfilesEditabilityState")
            .accessibilityValue(profilesEditabilityAccessibilityValue)

        Text(profilesUITestStateValue)
            .font(.caption2)
            .accessibilityIdentifier("settingsProfilesState")
            .accessibilityValue(profilesUITestStateValue)

        Text(backupController.canTransferBackup ? "enabled" : "disabled")
            .font(.caption2)
            .accessibilityIdentifier("settingsBackupTransferState")
            .accessibilityValue(backupController.canTransferBackup ? "enabled" : "disabled")

        Text("selectEnglishLanguage")
            .contentShape(Rectangle())
            .onTapGesture {
                appLanguageCode = "en"
            }
            .font(.caption2)
            .accessibilityIdentifier("settingsSelectEnglishLanguageForTest")

        if let geometricTheme = animalThemes.first(where: { $0.id == "geometric" }) {
            Text("selectGeometricTheme")
                .contentShape(Rectangle())
                .onTapGesture {
                    applyTheme(geometricTheme)
                }
                .font(.caption2)
                .accessibilityIdentifier("settingsSelectGeometricThemeForTest")
        }

        Text(selectedThemeAccessibilityValue)
            .font(.caption2)
            .accessibilityIdentifier("settingsSelectedThemeState")
            .accessibilityValue(selectedThemeAccessibilityValue)
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
            canTransferBackup: backupController.canTransferBackup,
            backupStatusMessage: backupStatusMessage,
            onExportBackup: prepareBackupExport,
            onImportBackup: { isImportingBackup = true },
            createProfileHelpText: profileRules.createProfileHelpText(),
            editProfileHelpText: profileRules.editProfileHelpText(),
            profileRowState: profileRules.rowState
        )
        .padding()
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: profileStore.profiles) { _, newProfiles in
            profileEditorState.syncDrafts(with: newProfiles)
        }
        .accessibilityIdentifier("settingsProfilesTabContent")
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

    private func prepareBackupExport() {
        do {
            let backup = try backupController.makeBackup(
                appPreferences: appPreferencesSnapshot,
                appVersion: appVersionDescription
            )
            backupDocument = AppBackupDocument(backup: backup)
            isExportingBackup = true
            backupStatusMessage = nil
        } catch {
            backupStatusMessage = error.localizedDescription
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasSecurityScope = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            let backup = try AppBackupController.decodeBackup(from: data)
            try backupController.importBackup(backup) { appPreferences in
                appLanguageCode = appPreferences.appLanguageCode
                enableBackgroundMusic = appPreferences.enableBackgroundMusic
                backgroundMusicTrackID = appPreferences.backgroundMusicTrackID
                backgroundMusicVolume = appPreferences.backgroundMusicVolume
            }
            backupStatusMessage = "Backup imported successfully."
        } catch {
            backupStatusMessage = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProfileStore())
        .environmentObject(HistoryStore())
        .environmentObject(ProfileSettingsStore())
}
