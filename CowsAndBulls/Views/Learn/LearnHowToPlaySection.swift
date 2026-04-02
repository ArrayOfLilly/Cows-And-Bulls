//
//  LearnHowToPlaySection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct LearnHowToPlaySection: View {
    var body: some View {
        LearnSection(title: localized("learn.section.how_to_play.title")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("learn.how_to_play.line1"))
                Text(localized("learn.how_to_play.line2"))
                Text(localized("learn.how_to_play.line3"))
            }
        }
    }
}
