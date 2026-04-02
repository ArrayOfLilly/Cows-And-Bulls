//
//  LearnSkillsSection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct LearnSkillsSection: View {
    var body: some View {
        LearnSection(title: localized("learn.section.skills.title")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.skill.logical_deduction"))
                Text(localized("learn.skill.pattern_recognition"))
                Text(localized("learn.skill.strategic_guessing"))
                Text(localized("learn.skill.memory"))
            }
            .multilineTextAlignment(.leading)
        }
    }
}
