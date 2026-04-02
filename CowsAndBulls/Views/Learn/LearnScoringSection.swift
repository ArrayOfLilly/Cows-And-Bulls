//
//  LearnScoringSection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct LearnScoringSection: View {
    var body: some View {
        LearnSection(title: localized("learn.section.scoring.title")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.score.base_intro"))
                Text(localized("learn.score.base_formula"))
                    .fontWeight(.semibold)

                Text(localized("learn.score.difficulty_title"))
                    .padding(.top, 4)
                Text(localized("learn.score.difficulty.repeats"))
                Text(localized("learn.score.difficulty.hard"))
                Text(localized("learn.score.difficulty.hidden"))
                Text(localized("learn.score.difficulty.guess_limit"))
                Text(localized("learn.score.difficulty.per_move_time"))
                Text(localized("learn.score.difficulty.total_time"))

                Text(localized("learn.score.performance_title"))
                    .padding(.top, 4)
                Text(localized("learn.score.performance_formula"))
                Text(localized("learn.score.performance_cap"))

                Text(localized("learn.score.jackpot_title"))
                    .padding(.top, 4)
                Text(localized("learn.score.jackpot_desc"))

                Text(localized("learn.score.final_formula"))
                    .fontWeight(.semibold)
                    .padding(.top, 4)
            }
        }
    }
}
