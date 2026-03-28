//
//  AppBackupPanelController.swift
//  CowsAndBulls
//

import Foundation
import AppKit
import UniformTypeIdentifiers

struct AppBackupPanelController {

    // MARK: - Export

    @MainActor
    static func exportBackup(
        backupController: AppBackupController,
        appPreferences: AppPreferencesSnapshot,
        appVersion: String
    ) async throws -> URL? {
        let backup = try backupController.makeBackup(
            appPreferences: appPreferences,
            appVersion: appVersion
        )
        let data = try AppBackupController.encodeBackup(backup)

        // beginSheetModal / begin are the correct way to show file panels on macOS.
        // runModal() called directly from a SwiftUI command closure triggers
        // REPORT_APP_ENTITLEMENTS_INSUFFICIENT because the menu tracking session
        // is still active on the main thread at that point.
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = defaultFilename()
        panel.message = "Choose where to save the backup"
        panel.prompt = "Save Backup"

        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            panel.directoryURL = downloads
        }

        let response = await withCheckedContinuation { continuation in
            if let window = NSApp.keyWindow {
                panel.beginSheetModal(for: window) { continuation.resume(returning: $0) }
            } else {
                panel.begin { continuation.resume(returning: $0) }
            }
        }

        guard response == .OK, let fileURL = panel.url else { return nil }

        try data.write(to: fileURL, options: .atomic)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        return fileURL
    }

    // MARK: - Import

    @MainActor
    static func importBackup(
        backupController: AppBackupController,
        applyAppPreferences: @MainActor (AppPreferencesSnapshot) -> Void
    ) async throws -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select a CowsAndBulls backup file"
        panel.prompt = "Import Backup"

        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            panel.directoryURL = downloads
        }

        let response = await withCheckedContinuation { continuation in
            if let window = NSApp.keyWindow {
                panel.beginSheetModal(for: window) { continuation.resume(returning: $0) }
            } else {
                panel.begin { continuation.resume(returning: $0) }
            }
        }

        guard response == .OK, let fileURL = panel.url else { return nil }

        let data = try Data(contentsOf: fileURL)
        let backup = try AppBackupController.decodeBackup(from: data)
        try backupController.importBackup(backup, applyAppPreferences: applyAppPreferences)
        return fileURL
    }

    // MARK: - Helpers

    private static func defaultFilename(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "cows-and-bulls-backup-\(formatter.string(from: now)).json"
    }
}
