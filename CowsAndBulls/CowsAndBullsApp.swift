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

    // @StateObject keeps shared stores alive for the app lifetime.
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
        // This is an AppKit/macOS-style language override path.
        // We write AppleLanguages so newly created localized strings resolve with the selected app language.
        // Some UI parts still require restart to fully refresh, which is why we also show restart prompts in Settings.
        if appLanguageCode == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([appLanguageCode], forKey: "AppleLanguages")
        }
    }

    private func showLocalizedAboutPanel() {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        // We use AppKit here because SwiftUI doesn't expose a fully customizable About panel API.
        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: localized("app.title"),
            .applicationVersion: localized("about.version.format", shortVersion, buildVersion)
        ]
        options[.credits] = NSAttributedString(string: localized("about.credits.body"))

        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Keeps background music playback in sync with persisted user settings.
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

        // AppKit window lookup prevents opening duplicate Learn windows.
        if let existing = NSApp.windows.first(where: { $0.identifier == windowID }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LearnView()
            .environmentObject(settingsStore)
            .environment(\.locale, appLocale)
        // NSHostingController embeds a SwiftUI view inside an AppKit NSWindow.
        // This is the standard bridge when you need explicit macOS window control.
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = windowID
        window.title = localized("learn.window.title")
        window.setContentSize(NSSize(width: 560, height: 700))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                .environmentObject(profileStore)
                .environmentObject(settingsStore)
                .environmentObject(gameSessionStore)
                .environmentObject(gameplayStore)
                // Environment locale keeps SwiftUI-localized text in sync with the selected app language.
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
            // CommandGroup(replacing:) is a macOS-specific way to override default app menu entries.
            CommandGroup(replacing: .appInfo) {
                Button(localized("app.menu.about.format", localized("app.title"))) {
                    showLocalizedAboutPanel()
                }
            }

            CommandGroup(replacing: .help) {
                Button(action: {
                    openLearnWindow()
                }, label: {
                    Text("Help")
                })
                .keyboardShortcut("/")
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
