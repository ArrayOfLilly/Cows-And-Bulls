//
//  CowsAndBullsApp.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI

@main
struct CowsAndBullsApp: App {
    @Environment(\.openWindow) private var openWindow

    @StateObject private var historyStore = HistoryStore()
    @AppStorage("appLanguageCode") private var appLanguageCode = "system"

    private var appLocale: Locale {
        if appLanguageCode == "system" {
            return Locale.current
        }
        return Locale(identifier: appLanguageCode)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                .environment(\.locale, appLocale)
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button(action: {
                    openWindow(id: "learn")
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
        
        Window("Learn", id: "learn") {
                LearnView()
                    .environment(\.locale, appLocale)
            }
    }
}
