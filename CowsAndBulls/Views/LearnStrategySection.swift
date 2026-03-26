//
//  LearnStrategySection.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
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
