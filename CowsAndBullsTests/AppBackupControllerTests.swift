import Testing
import Foundation
@testable import Cows___Bulls

@MainActor
@Suite("App Backup Controller Tests")
struct AppBackupControllerTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppBackupControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeContext() -> (
        defaults: UserDefaults,
        profileStore: ProfileStore,
        settingsStore: ProfileSettingsStore,
        historyStore: HistoryStore,
        sessionStore: GameSessionStore,
        controller: AppBackupController
    ) {
        let defaults = makeDefaults()
        let profileStore = ProfileStore(userDefaults: defaults)
        let settingsStore = ProfileSettingsStore(userDefaults: defaults)
        let historyStore = HistoryStore(userDefaults: defaults)
        let sessionStore = GameSessionStore()
        let controller = AppBackupController(
            profileStore: profileStore,
            settingsStore: settingsStore,
            historyStore: historyStore,
            gameSessionStore: sessionStore
        )
        return (defaults, profileStore, settingsStore, historyStore, sessionStore, controller)
    }

    @Test("Backup encodes and restores profiles, settings, history, and app preferences")
    func backupRoundTrip() throws {
        let source = makeContext()

        let alpha = source.profileStore.createProfile(named: "Alpha")
        source.settingsStore.setActiveProfileId(alpha.id)
        source.historyStore.setActiveProfileId(alpha.id)
        var alphaSettings = source.settingsStore.settings
        alphaSettings.maximumGuesses = 12
        alphaSettings.enableHardMode = true
        source.settingsStore.settings = alphaSettings
        source.historyStore.add(
            finalState: true,
            answer: "1234",
            steps: 2,
            score: 99,
            maxSteps: 12,
            hardMode: true,
            enableRepeats: false,
            guesses: ["1111", "1234"],
            guessResults: ["0|0", "4|0"],
            duration: 18,
            hasPerGuessLimit: false,
            hasTotalTimeLimit: false,
            perGuessLimit: 0,
            totalTimeLimit: 0,
            guessDurations: [10, 8]
        )

        let beta = source.profileStore.createProfile(named: "Beta")
        source.profileStore.selectProfile(id: beta.id)
        source.settingsStore.setActiveProfileId(beta.id)
        source.historyStore.setActiveProfileId(beta.id)
        var betaSettings = source.settingsStore.settings
        betaSettings.enableCelebration = false
        betaSettings.selectedAnimalThemeID = "geometric"
        source.settingsStore.settings = betaSettings
        source.historyStore.add(
            finalState: false,
            answer: "5678",
            steps: 1,
            score: 0,
            maxSteps: 10,
            hardMode: false,
            enableRepeats: false,
            guesses: ["1111"],
            guessResults: ["1|0"],
            duration: 7,
            hasPerGuessLimit: true,
            hasTotalTimeLimit: false,
            perGuessLimit: 15,
            totalTimeLimit: 0,
            guessDurations: [7],
            endReason: .surrender
        )

        let appPreferences = AppPreferencesSnapshot(
            appLanguageCode: "hu",
            enableBackgroundMusic: true,
            backgroundMusicTrackID: "Mushroom Background Music",
            backgroundMusicVolume: 0.55
        )

        let backup = try source.controller.makeBackup(appPreferences: appPreferences, appVersion: "2.3 (5)")
        let data = try AppBackupController.encodeBackup(backup)
        let decoded = try AppBackupController.decodeBackup(from: data)

        let target = makeContext()
        try target.controller.importBackup(decoded) { importedPreferences in
            #expect(importedPreferences == appPreferences)
        }

        #expect(target.profileStore.profiles.map(\.name).contains("Alpha"))
        #expect(target.profileStore.profiles.map(\.name).contains("Beta"))
        #expect(target.profileStore.selectedProfile?.name == "Beta")

        let importedAlpha = try #require(target.profileStore.profiles.first(where: { $0.name == "Alpha" }))
        target.settingsStore.setActiveProfileId(importedAlpha.id)
        target.historyStore.setActiveProfileId(importedAlpha.id)
        #expect(target.settingsStore.settings.maximumGuesses == 12)
        #expect(target.settingsStore.settings.enableHardMode == true)
        #expect(target.historyStore.items.first?.answer == "1234")

        let importedBeta = try #require(target.profileStore.profiles.first(where: { $0.name == "Beta" }))
        target.settingsStore.setActiveProfileId(importedBeta.id)
        target.historyStore.setActiveProfileId(importedBeta.id)
        #expect(target.settingsStore.settings.enableCelebration == false)
        #expect(target.settingsStore.settings.selectedAnimalThemeID == "geometric")
        #expect(target.historyStore.items.first?.endReason == .surrender)
    }

    @Test("Active game blocks export and import")
    func activeGameBlocksTransfer() {
        let context = makeContext()
        context.sessionStore.beginGame(with: .default)

        #expect(throws: AppBackupError.gameInProgress) {
            try context.controller.makeBackup(
                appPreferences: AppPreferencesSnapshot(
                    appLanguageCode: "system",
                    enableBackgroundMusic: false,
                    backgroundMusicTrackID: "Mushroom Background Music",
                    backgroundMusicVolume: 0.35
                ),
                appVersion: "2.3 (5)"
            )
        }

        let backup = AppBackup(
            schemaVersion: AppBackup.currentSchemaVersion,
            appVersion: "2.3 (5)",
            exportedAt: Date(),
            selectedProfileID: context.profileStore.selectedProfileId,
            profiles: context.profileStore.profiles,
            profileSettings: [context.profileStore.selectedProfileId: .default],
            history: [context.profileStore.selectedProfileId: []],
            appPreferences: AppPreferencesSnapshot(
                appLanguageCode: "system",
                enableBackgroundMusic: false,
                backgroundMusicTrackID: "Mushroom Background Music",
                backgroundMusicVolume: 0.35
            )
        )

        #expect(throws: AppBackupError.gameInProgress) {
            try context.controller.importBackup(backup) { _ in }
        }
    }

    @Test("Unsupported schema version is rejected")
    func unsupportedSchemaVersionRejected() {
        let context = makeContext()
        let backup = AppBackup(
            schemaVersion: 99,
            appVersion: "9.9 (99)",
            exportedAt: Date(),
            selectedProfileID: context.profileStore.selectedProfileId,
            profiles: context.profileStore.profiles,
            profileSettings: [context.profileStore.selectedProfileId: .default],
            history: [context.profileStore.selectedProfileId: []],
            appPreferences: AppPreferencesSnapshot(
                appLanguageCode: "system",
                enableBackgroundMusic: false,
                backgroundMusicTrackID: "Mushroom Background Music",
                backgroundMusicVolume: 0.35
            )
        )

        #expect(throws: AppBackupError.unsupportedSchemaVersion(99)) {
            try AppBackupController.validateBackup(backup)
        }
    }
}
