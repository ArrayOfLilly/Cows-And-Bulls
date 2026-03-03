//
//  LearnView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

/// In-app learning reference that explains rules, scoring, and game options.
/// In-app reference screen with localized explanations and themed bull/cow examples.
struct LearnView: View {
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"

    var body: some View {
        ScrollView {
            Text(localized("learn.title.rules"))
                .font(Font.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("learn.section.objective.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.objective.line1"))
                Text(localized("learn.objective.line2"))
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("learn.section.skills.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.skill.logical_deduction"))
                Text(localized("learn.skill.pattern_recognition"))
                Text(localized("learn.skill.strategic_guessing"))
                Text(localized("learn.skill.memory"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("learn.section.how_to_play.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.how_to_play.line1"))
                Text(localized("learn.how_to_play.line2"))
                Text(localized("learn.how_to_play.line3"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("learn.section.each_guess.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading) {
                HStack {
                    HStack(alignment: .center, spacing: 2) {
                        Text(localized("learn.term.bull"))
                            .fontWeight(.bold)
                        Text("(")
                        Image(selectedBullAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(")")
                    }
                    Text(localized("learn.term.bull.description"))
                }
                .padding(1)

                HStack {
                    HStack(alignment: .center, spacing: 2) {
                        Text(localized("learn.term.cow"))
                            .fontWeight(.bold)
                        Text("(")
                        Image(selectedCowAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(")")
                    }
                    Text(localized("learn.term.cow.description"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
            
            Divider()
            .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.strategy.line1"))
                Text(localized("learn.strategy.line2"))
                Text(localized("learn.strategy.line3"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
                .font(.body)
                .padding()

            Text(localized("learn.section.scoring.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
            .padding()
            .font(.body)

            Text(localized("learn.section.options.title"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 10) {
                // Structured option rows keep labels aligned across localized text lengths.
                optionRow(localized("learn.options.step_count.title"), localized("learn.options.step_count.desc"))
                optionRow(localized("learn.options.answer_length.title"), localized("learn.options.answer_length.desc"))
                optionRow(localized("learn.options.repeating.title"), localized("learn.options.repeating.desc"))
                optionRow(localized("learn.options.hard_mode.title"), localized("learn.options.hard_mode.desc"))
                optionRow(localized("learn.options.show_steps.title"), localized("learn.options.show_steps.desc"))
                optionRow(localized("learn.options.theming.title"), localized("learn.options.theming.desc"))
                optionRow(localized("learn.options.time_limit.title"), localized("learn.options.time_limit.desc"))
                optionRow(localized("learn.options.per_game_time_limit.title"), localized("learn.options.per_game_time_limit.desc"))
                optionRow(localized("learn.options.sound.title"), localized("learn.options.sound.desc"))
                optionRow(localized("learn.options.background_music.title"), localized("learn.options.background_music.desc"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
            .padding()

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
        .padding(20)
        .frame(minWidth: 800, maxWidth: .infinity)
    }

    /// Two-column option row used in the Options section for aligned labels.
    private func optionRow(_ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .fontWeight(.bold)
                .frame(width: 130, alignment: .leading)
            Text(description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}

#Preview {
    LearnView()
}
