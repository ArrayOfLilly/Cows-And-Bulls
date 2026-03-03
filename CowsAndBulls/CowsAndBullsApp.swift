//
//  CowsAndBullsApp.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit

@main
/// App entry point: injects shared state, locale, and command menu behavior.
struct CowsAndBullsApp: App {
    // @StateObject keeps one shared HistoryStore instance alive for the app lifetime.
    @StateObject private var historyStore = HistoryStore()
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
            .applicationName: localized("Cows and Bulls"),
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

    private func openLearnWindow() {
        let windowID = NSUserInterfaceItemIdentifier("learnWindow")

        // AppKit window lookup prevents opening duplicate Learn windows.
        if let existing = NSApp.windows.first(where: { $0.identifier == windowID }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LearnView()
            .environment(\.locale, appLocale)
        // NSHostingController embeds a SwiftUI view inside an AppKit NSWindow.
        // This is the standard bridge when you need explicit macOS window control.
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = windowID
        window.title = localized("Learn")
        window.setContentSize(NSSize(width: 560, height: 700))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                // Environment locale keeps SwiftUI-localized text in sync with the selected app language.
                .environment(\.locale, appLocale)
                .onAppear {
                    synchronizeBundleLanguagePreference()
                    applyBackgroundMusicSettings()
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
                Button(localized("About %@", localized("Cows and Bulls"))) {
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
        }
    }
}
