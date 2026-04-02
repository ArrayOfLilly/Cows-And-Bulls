//
//  AppBackup.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct AppPreferencesSnapshot: Codable, Equatable {
    var appLanguageCode: String
    var enableBackgroundMusic: Bool
    var backgroundMusicTrackID: String
    var backgroundMusicVolume: Double
}

struct AppBackup: Codable {
    static let currentSchemaVersion = 1
    static let placeholder = AppBackup(
        schemaVersion: currentSchemaVersion,
        appVersion: "0.0 (0)",
        exportedAt: .distantPast,
        selectedProfileID: "placeholder",
        profiles: [
            PlayerProfile(id: "placeholder", name: "Placeholder", createdAt: .distantPast)
        ],
        profileSettings: ["placeholder": .default],
        history: ["placeholder": []],
        appPreferences: AppPreferencesSnapshot(
            appLanguageCode: "system",
            enableBackgroundMusic: false,
            backgroundMusicTrackID: "Mushroom Background Music",
            backgroundMusicVolume: 0.35
        )
    )

    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let selectedProfileID: String
    let profiles: [PlayerProfile]
    let profileSettings: [String: ProfileSettings]
    let history: [String: [HistoryItem]]
    let appPreferences: AppPreferencesSnapshot
}

enum AppBackupError: LocalizedError, Equatable {
    case gameInProgress
    case unsupportedSchemaVersion(Int)
    case invalidBackup

    var errorDescription: String? {
        switch self {
        case .gameInProgress:
            return "Backups are only available when no game is in progress."
        case .unsupportedSchemaVersion(let version):
            return "This backup uses schema version \(version), which this app cannot import."
        case .invalidBackup:
            return "The selected backup file is invalid."
        }
    }
}

struct AppBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let backup: AppBackup

    init(backup: AppBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw AppBackupError.invalidBackup
        }
        self.backup = try AppBackupController.decodeBackup(from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try AppBackupController.encodeBackup(backup)
        return .init(regularFileWithContents: data)
    }
}
