//
//  ProfileSettingsStore.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 03. 10..
//

import Foundation
internal import Combine

struct ProfileSettings: Codable, Equatable {
    var maximumGuesses: Int
    var showGuessCount: Bool
    var answerLength: Int
    var enableCelebration: Bool
    var enableHardMode: Bool
    var enableRepeats: Bool
    var enableSoundEffects: Bool
    var soundEffectsVolume: Double
    var enablePerGuessTimeLimit: Bool
    var enableGameTimeLimit: Bool
    var perGuessTimeLimitSeconds: Int
    var gameTimeLimitSeconds: Int
    var selectedAnimalThemeID: String
    var selectedBullAssetName: String
    var selectedCowAssetName: String

    static let `default` = ProfileSettings(
        maximumGuesses: 10,
        showGuessCount: false,
        answerLength: 4,
        enableCelebration: true,
        enableHardMode: false,
        enableRepeats: false,
        enableSoundEffects: true,
        soundEffectsVolume: 0.8,
        enablePerGuessTimeLimit: false,
        enableGameTimeLimit: false,
        perGuessTimeLimitSeconds: 30,
        gameTimeLimitSeconds: 300,
        selectedAnimalThemeID: "classic",
        selectedBullAssetName: "Bull",
        selectedCowAssetName: "Cow"
    )

    static func fromLegacyDefaults(_ defaults: UserDefaults) -> ProfileSettings {
        var settings = ProfileSettings.default
        if defaults.object(forKey: "maximumGuesses") != nil { settings.maximumGuesses = defaults.integer(forKey: "maximumGuesses") }
        if defaults.object(forKey: "showGuessCount") != nil { settings.showGuessCount = defaults.bool(forKey: "showGuessCount") }
        if defaults.object(forKey: "answerLength") != nil { settings.answerLength = defaults.integer(forKey: "answerLength") }
        if defaults.object(forKey: "enableCelebration") != nil { settings.enableCelebration = defaults.bool(forKey: "enableCelebration") }
        if defaults.object(forKey: "enableHardMode") != nil { settings.enableHardMode = defaults.bool(forKey: "enableHardMode") }
        if defaults.object(forKey: "enableRepeats") != nil { settings.enableRepeats = defaults.bool(forKey: "enableRepeats") }
        if defaults.object(forKey: "enableSoundEffects") != nil { settings.enableSoundEffects = defaults.bool(forKey: "enableSoundEffects") }
        if defaults.object(forKey: "soundEffectsVolume") != nil { settings.soundEffectsVolume = defaults.double(forKey: "soundEffectsVolume") }
        if defaults.object(forKey: "enablePerGuessTimeLimit") != nil { settings.enablePerGuessTimeLimit = defaults.bool(forKey: "enablePerGuessTimeLimit") }
        if defaults.object(forKey: "enableGameTimeLimit") != nil { settings.enableGameTimeLimit = defaults.bool(forKey: "enableGameTimeLimit") }
        if defaults.object(forKey: "perGuessTimeLimitSeconds") != nil { settings.perGuessTimeLimitSeconds = defaults.integer(forKey: "perGuessTimeLimitSeconds") }
        if defaults.object(forKey: "gameTimeLimitSeconds") != nil { settings.gameTimeLimitSeconds = defaults.integer(forKey: "gameTimeLimitSeconds") }
        if defaults.object(forKey: "selectedAnimalThemeID") != nil { settings.selectedAnimalThemeID = defaults.string(forKey: "selectedAnimalThemeID") ?? settings.selectedAnimalThemeID }
        if defaults.object(forKey: "selectedBullAssetName") != nil { settings.selectedBullAssetName = defaults.string(forKey: "selectedBullAssetName") ?? settings.selectedBullAssetName }
        if defaults.object(forKey: "selectedCowAssetName") != nil { settings.selectedCowAssetName = defaults.string(forKey: "selectedCowAssetName") ?? settings.selectedCowAssetName }
        return settings
    }
}

@MainActor
final class ProfileSettingsStore: ObservableObject {
    @Published var settings: ProfileSettings { didSet { save() } }

    private let userDefaults: UserDefaults
    private var storageKey: String
    private var isLoading = false

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "profile.settings"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.settings = .default
        load()
    }

    func setActiveProfileId(_ profileId: String) {
        let nextKey = "profile.settings.\(profileId)"
        guard storageKey != nextKey else { return }
        save()
        storageKey = nextKey
        load()
    }

    func deleteProfileData(profileId: String) {
        let key = "profile.settings.\(profileId)"
        userDefaults.removeObject(forKey: key)
        if storageKey == key {
            settings = .default
        }
    }

    func exportedSettings(for profileIDs: [String]) -> [String: ProfileSettings] {
        Dictionary(uniqueKeysWithValues: profileIDs.map { profileID in
            let key = storageKey(for: profileID)
            let value: ProfileSettings
            if let data = userDefaults.data(forKey: key),
               let decoded = try? JSONDecoder().decode(ProfileSettings.self, from: data) {
                value = decoded
            } else {
                value = .default
            }
            return (profileID, value)
        })
    }

    func replaceAllSettings(_ importedSettings: [String: ProfileSettings], activeProfileId: String) {
        removeAllStoredSettings()

        for (profileID, settings) in importedSettings {
            let key = storageKey(for: profileID)
            if let encoded = try? JSONEncoder().encode(settings) {
                userDefaults.set(encoded, forKey: key)
            }
        }

        storageKey = storageKey(for: activeProfileId)
        load()
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        guard let data = userDefaults.data(forKey: storageKey) else {
            settings = ProfileSettings.fromLegacyDefaults(userDefaults)
            save()
            return
        }
        if let decoded = try? JSONDecoder().decode(ProfileSettings.self, from: data) {
            settings = decoded
        } else {
            settings = ProfileSettings.fromLegacyDefaults(userDefaults)
            save()
        }
    }

    private func storageKey(for profileId: String) -> String {
        "profile.settings.\(profileId)"
    }

    private func removeAllStoredSettings() {
        let keys = userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("profile.settings.") }
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func save() {
        guard isLoading == false else { return }
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
