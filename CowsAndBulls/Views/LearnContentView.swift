//
//  LearnContentView.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import SwiftUI

struct LearnContentView: View {
    let bullAssetName: String
    let cowAssetName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(localized("learn.title.rules"))
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            LearnDivider()
            LearnObjectiveSection()
            LearnDivider()
            LearnSkillsSection()
            LearnDivider()
            LearnHowToPlaySection()
            LearnDivider()
            LearnGuessExplanationSection(
                bullAssetName: bullAssetName,
                cowAssetName: cowAssetName
            )
            LearnDivider()
            LearnStrategySection()
            LearnDivider()
            LearnScoringSection()
            LearnDivider()
            LearnOptionsSection()
            LearnDivider()
            LearnFooterSection()
        }
    }
}

private struct LearnDivider: View {
    var body: some View {
        Divider()
            .padding()
    }
}

private struct LearnFooterSection: View {
    var body: some View {
        Text(localized("learn.footer.enjoy"))
            .font(.title2.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.primary.opacity(0.08), radius: 6, y: 2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
}
