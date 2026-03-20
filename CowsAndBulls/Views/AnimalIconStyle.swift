//
//  AnimalIconStyle.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 03. 11..
//

import SwiftUI

private struct AnimalIconStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let isLight = colorScheme == .light
        let shadowColor = isLight ? Color.black.opacity(0.35) : Color.white.opacity(0.01)

        return content
            .shadow(color: shadowColor, radius: isLight ? 2 : 0, x: 0, y: 2)
    }
}

extension View {
    func animalIconStyle(cornerRadius: CGFloat = 4) -> some View {
        modifier(AnimalIconStyle(cornerRadius: cornerRadius))
    }
}
