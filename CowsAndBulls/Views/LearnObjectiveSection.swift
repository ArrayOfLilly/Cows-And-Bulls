//
//  LearnObjectiveSection.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import SwiftUI

struct LearnObjectiveSection: View {
    var body: some View {
        LearnSection(title: localized("learn.section.objective.title")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.objective.line1"))
                Text(localized("learn.objective.line2"))
            }
            .font(.body)
        }
    }
}
