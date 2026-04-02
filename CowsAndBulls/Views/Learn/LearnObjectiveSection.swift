//
//  LearnObjectiveSection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
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
