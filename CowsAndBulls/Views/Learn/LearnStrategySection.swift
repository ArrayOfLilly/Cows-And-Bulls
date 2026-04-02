//
//  LearnStrategySection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct LearnStrategySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("learn.strategy.line1"))
            Text(localized("learn.strategy.line2"))
            Text(localized("learn.strategy.line3"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}
