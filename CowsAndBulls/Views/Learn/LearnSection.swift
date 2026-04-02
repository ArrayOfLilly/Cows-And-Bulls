//
//  LearnSection.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct LearnSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }
}
