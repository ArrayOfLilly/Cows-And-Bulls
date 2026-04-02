//
//  LearnView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

/// In-app learning reference that explains rules, scoring, and game options.
struct LearnView: View {
    @EnvironmentObject private var settingsStore: ProfileSettingsStore

    var body: some View {
        ScrollView {
            LearnContentView(
                bullAssetName: settingsStore.settings.selectedBullAssetName,
                cowAssetName: settingsStore.settings.selectedCowAssetName
            )
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }
}

#Preview {
    LearnView()
        .environmentObject(ProfileSettingsStore())
}
