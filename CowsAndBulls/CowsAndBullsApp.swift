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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
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
        }
        
        Window("Learn", id: "learn") {
                LearnView()
            }
    }
}
