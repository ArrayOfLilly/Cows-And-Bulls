//
//  CowsAndBullsApp.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
/// App entry point: injects shared state, locale, and command menu behavior.
struct CowsAndBullsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var profileStore = ProfileStore()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var settingsStore = ProfileSettingsStore()
    @StateObject private var gameSessionStore = GameSessionStore()
    @StateObject private var gameplayStore = GameplayStore()
    @AppStorage("appLanguageCode") private var appLanguageCode = "system"
    @AppStorage("enableBackgroundMusic") private var enableBackgroundMusic = false
    @AppStorage("backgroundMusicTrackID") private var backgroundMusicTrackID = "Mushroom Background Music"
    @AppStorage("backgroundMusicVolume") private var backgroundMusicVolume = 0.35

    private var appLocale: Locale {
        if appLanguageCode == "system" {
            return Locale.current
        }
        return Locale(identifier: appLanguageCode)
    }

    private func synchronizeBundleLanguagePreference() {
        if appLanguageCode == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([appLanguageCode], forKey: "AppleLanguages")
        }
    }

    private func showLocalizedAboutPanel() {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: localized("app.title"),
            .applicationVersion: localized("about.version.format", shortVersion, buildVersion)
        ]
        options[.credits] = NSAttributedString(string: localized("about.credits.body"))

        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func applyBackgroundMusicSettings() {
        SoundPlayer.shared.updateBackgroundMusic(
            enabled: enableBackgroundMusic,
            trackID: backgroundMusicTrackID,
            volume: backgroundMusicVolume
        )
    }

    private func applyUITestOverridesIfNeeded() {
        let environment = ProcessInfo.processInfo.environment
        if let forcedLanguageCode = environment["UITEST_FORCE_LANGUAGE"] {
            appLanguageCode = forcedLanguageCode
        }
        if let seededProfiles = environment["UITEST_PROFILE_NAMES"] {
            let names = seededProfiles
                .split(separator: "|")
                .map(String.init)
            profileStore.replaceProfilesForUITesting(names: names)
        }
    }

    private func openLearnWindow() {
        let windowID = NSUserInterfaceItemIdentifier("learnWindow")

        if let existing = NSApp.windows.first(where: { $0.identifier == windowID }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LearnView()
            .environmentObject(settingsStore)
            .environment(\.locale, appLocale)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = windowID
        window.title = localized("learn.window.title")
        window.setContentSize(NSSize(width: 560, height: 700))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openPrivacyPolicyWindow() {
        let windowID = NSUserInterfaceItemIdentifier("privacyPolicyWindow")

        if let existing = NSApp.windows.first(where: { $0.identifier == windowID }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = PrivacyPolicyView()
            .environment(\.locale, appLocale)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = windowID
        window.title = localized("privacy.title")
        window.setContentSize(NSSize(width: 640, height: 760))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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

    private func showBackupAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: localized("backup.alert.ok"))
        alert.runModal()
    }

    private func exportBackupFromMenu() {
        Task { @MainActor in
            do {
                if let fileURL = try await AppBackupPanelController.exportBackup(
                    backupController: backupController,
                    appPreferences: appPreferencesSnapshot,
                    appVersion: appVersionDescription
                ) {
                    showBackupAlert(
                        title: localized("backup.alert.exported.title"),
                        message: fileURL.lastPathComponent
                    )
                }
            } catch {
                showBackupAlert(
                    title: localized("backup.alert.export_failed.title"),
                    message: error.localizedDescription
                )
            }
        }
    }

    private func importBackupFromMenu() {
        Task { @MainActor in
            do {
                guard let fileURL = try await AppBackupPanelController.importBackup(
                    backupController: backupController,
                    applyAppPreferences: { appPreferences in
                        appLanguageCode = appPreferences.appLanguageCode
                        enableBackgroundMusic = appPreferences.enableBackgroundMusic
                        backgroundMusicTrackID = appPreferences.backgroundMusicTrackID
                        backgroundMusicVolume = appPreferences.backgroundMusicVolume
                    }
                ) else { return }
                showBackupAlert(
                    title: localized("backup.alert.imported.title"),
                    message: fileURL.lastPathComponent
                )
            } catch {
                showBackupAlert(
                    title: localized("backup.alert.import_failed.title"),
                    message: error.localizedDescription
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                .environmentObject(profileStore)
                .environmentObject(settingsStore)
                .environmentObject(gameSessionStore)
                .environmentObject(gameplayStore)
                .environment(\.locale, appLocale)
                .onAppear {
                    applyUITestOverridesIfNeeded()
                    synchronizeBundleLanguagePreference()
                    applyBackgroundMusicSettings()
                    historyStore.setActiveProfileId(profileStore.selectedProfileId)
                    settingsStore.setActiveProfileId(profileStore.selectedProfileId)
                }
                .onChange(of: profileStore.selectedProfileId) {
                    historyStore.setActiveProfileId(profileStore.selectedProfileId)
                    settingsStore.setActiveProfileId(profileStore.selectedProfileId)
                }
                .onChange(of: appLanguageCode) {
                    synchronizeBundleLanguagePreference()
                }
                .onChange(of: enableBackgroundMusic) {
                    applyBackgroundMusicSettings()
                }
                .onChange(of: backgroundMusicTrackID) {
                    applyBackgroundMusicSettings()
                }
                .onChange(of: backgroundMusicVolume) {
                    applyBackgroundMusicSettings()
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(localized("app.menu.about.format", localized("app.title"))) {
                    showLocalizedAboutPanel()
                }
            }

            CommandGroup(after: .saveItem) {
                Divider()
                Button(localized("backup.action.export.ellipsis")) {
                    exportBackupFromMenu()
                }
                .disabled(gameSessionStore.gameInProgress)

                Button(localized("backup.action.import.ellipsis")) {
                    importBackupFromMenu()
                }
                .disabled(gameSessionStore.gameInProgress)
            }

            CommandGroup(replacing: .help) {
                Button(action: {
                    openLearnWindow()
                }, label: {
                    Text(localized("learn.window.title"))
                })
                .keyboardShortcut("/")

                Button(action: {
                    openPrivacyPolicyWindow()
                }, label: {
                    Text(localized("privacy.title"))
                })
            }
        }

        Settings {
            SettingsView()
                .environment(\.locale, appLocale)
                .environmentObject(profileStore)
                .environmentObject(historyStore)
                .environmentObject(settingsStore)
                .environmentObject(gameSessionStore)
                .environmentObject(gameplayStore)
        }
        .defaultSize(width: 460, height: 520)
        .windowResizability(.contentMinSize)
    }
}
