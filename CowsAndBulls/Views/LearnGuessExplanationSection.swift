//
//  LearnGuessExplanationSection.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import SwiftUI

struct LearnGuessExplanationSection: View {
    let bullAssetName: String
    let cowAssetName: String

    var body: some View {
        LearnSection(title: localized("learn.section.each_guess.title")) {
            VStack(alignment: .leading) {
                LearnGuessTermRow(
                    title: localized("learn.term.bull"),
                    assetName: bullAssetName,
                    description: localized("learn.term.bull.description")
                )
                .padding(1)

                LearnGuessTermRow(
                    title: localized("learn.term.cow"),
                    assetName: cowAssetName,
                    description: localized("learn.term.cow.description")
                )
            }
            .padding(.bottom, 10)
        }
    }
}

private struct LearnGuessTermRow: View {
    let title: String
    let assetName: String
    let description: String

    var body: some View {
        HStack {
            HStack(alignment: .center, spacing: 2) {
                Text(title)
                    .fontWeight(.bold)
                Text("(")
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .animalIconStyle()
                Text(")")
            }
            Text(description)
        }
    }
}
