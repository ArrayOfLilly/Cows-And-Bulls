//
//  LearnOptionsSection.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import SwiftUI

struct LearnOptionsSection: View {
    var body: some View {
        LearnSection(title: localized("learn.section.options.title")) {
            VStack(alignment: .leading, spacing: 10) {
                LearnOptionRow(localized("learn.options.step_count.title"), localized("learn.options.step_count.desc"))
                LearnOptionRow(localized("learn.options.answer_length.title"), localized("learn.options.answer_length.desc"))
                LearnOptionRow(localized("learn.options.repeating.title"), localized("learn.options.repeating.desc"))
                LearnOptionRow(localized("learn.options.hard_mode.title"), localized("learn.options.hard_mode.desc"))
                LearnOptionRow(localized("learn.options.show_steps.title"), localized("learn.options.show_steps.desc"))
                LearnOptionRow(localized("learn.options.theming.title"), localized("learn.options.theming.desc"))
                LearnOptionRow(localized("learn.options.profiles.title"), localized("learn.options.profiles.desc"))
                LearnOptionRow(localized("learn.options.time_limit.title"), localized("learn.options.time_limit.desc"))
                LearnOptionRow(localized("learn.options.per_game_time_limit.title"), localized("learn.options.per_game_time_limit.desc"))
                LearnOptionRow(localized("learn.options.sound.title"), localized("learn.options.sound.desc"))
                LearnOptionRow(localized("learn.options.background_music.title"), localized("learn.options.background_music.desc"))
            }
        }
    }
}

private struct LearnOptionRow: View {
    let title: String
    let description: String

    init(_ title: String, _ description: String) {
        self.title = title
        self.description = description
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .fontWeight(.bold)
                .frame(width: 130, alignment: .leading)
            Text(description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
