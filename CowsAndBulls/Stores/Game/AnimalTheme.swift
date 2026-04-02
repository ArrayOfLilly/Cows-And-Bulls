//
//  AnimalTheme.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

/// Metadata model for one selectable visual theme pair.
struct AnimalTheme: Identifiable {
    let id: String
    let nameKey: String
    let bullAsset: String
    let cowAsset: String

    static let all: [AnimalTheme] = [
        .init(id: "classic", nameKey: "theme.classic", bullAsset: "Bull", cowAsset: "Cow"),
        .init(id: "geometric", nameKey: "theme.geometric", bullAsset: "Bull9", cowAsset: "Cow9"),
        .init(id: "vivid", nameKey: "theme.vivid", bullAsset: "Bull5", cowAsset: "Cow5"),
        .init(id: "chubby", nameKey: "theme.chubby", bullAsset: "Bull7", cowAsset: "Cow7"),
        .init(id: "classic 2", nameKey: "theme.classic2", bullAsset: "Bull10", cowAsset: "Cow10"),
        .init(id: "black&white", nameKey: "theme.black_white", bullAsset: "Bull13.3", cowAsset: "Cow13.2"),
        .init(id: "modern", nameKey: "theme.modern", bullAsset: "Bull14", cowAsset: "Cow4"),
        .init(id: "faces", nameKey: "theme.faces", bullAsset: "Bull15", cowAsset: "Cow15"),
        .init(id: "buffalo", nameKey: "theme.buffalo", bullAsset: "Bull19", cowAsset: "Cow10.2"),
        .init(id: "marriage story", nameKey: "theme.marriage_story", bullAsset: "Bull20", cowAsset: "Cow24"),
        .init(id: "faces 2", nameKey: "theme.faces2", bullAsset: "Bull22", cowAsset: "Cow23.2")
    ]
}
