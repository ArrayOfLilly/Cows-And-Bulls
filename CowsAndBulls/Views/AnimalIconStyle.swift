//
//  AnimalIconStyle.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 03. 11..
//

import SwiftUI

private struct AnimalIconStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        let isLight = colorScheme == .light
        let borderColor = isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.10)
        let backgroundColor = isLight ? Color.white.opacity(0.35) : Color.white.opacity(0.06)
        let shadowColor = isLight ? Color.black.opacity(0.18) : Color.black.opacity(0.22)

        return content
            .clipShape(shape)
            .background(shape.fill(backgroundColor))
            .overlay(shape.strokeBorder(borderColor, lineWidth: 0.8))
            .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
    }
}

extension View {
    func animalIconStyle() -> some View {
        modifier(AnimalIconStyle())
    }
}
