//
//  AppBackupController.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

struct AppBackupController {
    let profileStore: ProfileStore
    let settingsStore: ProfileSettingsStore
    let historyStore: HistoryStore
    let gameSessionStore: GameSessionStore

    @MainActor
    var canTransferBackup: Bool {
        gameSessionStore.gameInProgress == false
    }

    @MainActor
    func makeBackup(appPreferences: AppPreferencesSnapshot, appVersion: String) throws -> AppBackup {
        guard canTransferBackup else {
            throw AppBackupError.gameInProgress
        }

        let profiles = profileStore.profiles
        guard profiles.isEmpty == false else {
            throw AppBackupError.invalidBackup
        }

        let profileIDs = profiles.map(\.id)
        return AppBackup(
            schemaVersion: AppBackup.currentSchemaVersion,
            appVersion: appVersion,
            exportedAt: Date(),
            selectedProfileID: profileStore.selectedProfileId,
            profiles: profiles,
            profileSettings: settingsStore.exportedSettings(for: profileIDs),
            history: historyStore.exportedHistory(for: profileIDs),
            appPreferences: appPreferences
        )
    }

    @MainActor
    func importBackup(_ backup: AppBackup, applyAppPreferences: (AppPreferencesSnapshot) -> Void) throws {
        guard canTransferBackup else {
            throw AppBackupError.gameInProgress
        }
        try Self.validateBackup(backup)

        profileStore.replaceAllProfiles(backup.profiles, selectedProfileId: backup.selectedProfileID)
        let activeProfileId = profileStore.selectedProfileId
        settingsStore.replaceAllSettings(backup.profileSettings, activeProfileId: activeProfileId)
        historyStore.replaceAllHistory(backup.history, activeProfileId: activeProfileId)
        settingsStore.setActiveProfileId(activeProfileId)
        historyStore.setActiveProfileId(activeProfileId)
        applyAppPreferences(backup.appPreferences)
    }

    static func encodeBackup(_ backup: AppBackup) throws -> Data {
        try validateBackup(backup)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func decodeBackup(from data: Data) throws -> AppBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(AppBackup.self, from: data)
        try validateBackup(backup)
        return backup
    }

    static func validateBackup(_ backup: AppBackup) throws {
        guard backup.schemaVersion == AppBackup.currentSchemaVersion else {
            throw AppBackupError.unsupportedSchemaVersion(backup.schemaVersion)
        }
        guard backup.profiles.isEmpty == false else {
            throw AppBackupError.invalidBackup
        }
        guard backup.profiles.contains(where: { $0.id == backup.selectedProfileID }) else {
            throw AppBackupError.invalidBackup
        }
    }
}
