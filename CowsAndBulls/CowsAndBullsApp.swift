//
//  CowsAndBullsApp.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit

@main
struct CowsAndBullsApp: App {
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
            .applicationName: localized("Cows and Bulls"),
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

    private func openLearnWindow() {
        let windowID = NSUserInterfaceItemIdentifier("learnWindow")

        if let existing = NSApp.windows.first(where: { $0.identifier == windowID }) {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LearnView()
            .environment(\.locale, appLocale)
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
