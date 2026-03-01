//
//  LearnView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

struct LearnView: View {
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"

    var body: some View {
        ScrollView {
            Text(localized("Rules of Games"))
                .font(Font.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("Objective"))
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

            Text(localized("Skills Learned"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("Logical Deduction – Narrowing possibilities based on feedback."))
                Text(localized("Pattern Recognition – Identifying overlap between guesses."))
                Text(localized("Strategic Guessing – Choosing guesses that eliminate the most options."))
                Text(localized("Memory – Tracking which guesses have ruled out or confirmed symbols."))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("How to play"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("The computer choose a sequence of digits (you can set the length between 3 and 8 digits) which the code-breaker cannot see."))
                Text(localized("Digits can be from 0–9. Decide if repeats are allowed, currently repeats are not allowed."))
                Text(localized("Code-breaker makes the first guess."))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
                .padding()

            Text(localized("For each guess:"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading) {
                HStack {
                    HStack(alignment: .center, spacing: 2) {
                        Text(localized("Bull"))
                            .fontWeight(.bold)
                        Text("(")
                        Image(selectedBullAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(")")
                    }
                    Text(localized("Correct digit in the correct position."))
                }
                .padding(1)

                HStack {
                    HStack(alignment: .center, spacing: 2) {
                        Text(localized("Cow"))
                            .fontWeight(.bold)
                        Text("(")
                        Image(selectedCowAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(")")
                    }
                    Text(localized("Correct digit in the wrong position."))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
            
            Divider()
            .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("Keep track of which numbers have been confirmed or eliminated, and which positions might be correct."))
                Text(localized("The code-breaker keeps making guesses, one per turn, using feedback to narrow the possibilities."))
                Text(localized("The code-breaker wins by matching the code exactly, in less round than the current limit is. (You can set the limit as you wish.)"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
                .font(.body)
                .padding()

            Text(localized("Scoring:"))
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

            Text(localized("Options:"))
                .font(Font.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 10) {
                optionRow(localized("learn.options.step_count.title"), localized("learn.options.step_count.desc"))
                optionRow(localized("learn.options.answer_length.title"), localized("learn.options.answer_length.desc"))
                optionRow(localized("learn.options.repeating.title"), localized("learn.options.repeating.desc"))
                optionRow(localized("learn.options.hard_mode.title"), localized("learn.options.hard_mode.desc"))
                optionRow(localized("learn.options.show_steps.title"), localized("learn.options.show_steps.desc"))
                optionRow(localized("learn.options.theming.title"), localized("learn.options.theming.desc"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            Divider()
            .padding()

            Text(localized("Enjoy the game!"))
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
        .frame(maxWidth: 500)
    }

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
