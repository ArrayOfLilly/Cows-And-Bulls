//
//  SettingsViewSupport.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

enum SettingsTab: Hashable {
    case game
    case advanced
    case sound
    case music
    case profiles
    case language
    case theme

    nonisolated init?(uiTestValue: String) {
        switch uiTestValue {
        case "game": self = .game
        case "advanced": self = .advanced
        case "sound": self = .sound
        case "music": self = .music
        case "profiles": self = .profiles
        case "language": self = .language
        case "theme": self = .theme
        default: return nil
        }
    }

    var accessibilityValue: String {
        switch self {
        case .game: "game"
        case .advanced: "advanced"
        case .sound: "sound"
        case .music: "music"
        case .profiles: "profiles"
        case .language: "language"
        case .theme: "theme"
        }
    }
}

struct SettingsProfilesAccessibilitySnapshot {
    let canRenameProfiles: Bool
    let profiles: [PlayerProfile]
    let profileRules: ProfileSettingsRules

    private func reorderState(for index: Int) -> String? {
        guard profiles.indices.contains(index) else { return nil }
        let rowState = profileRules.rowState(for: profiles[index])
        let moveUpState = rowState.canMoveUp ? "enabled" : "disabled"
        let moveDownState = rowState.canMoveDown ? "enabled" : "disabled"
        return "up:\(moveUpState),down:\(moveDownState)"
    }

    var editabilityValue: String {
        let editability = canRenameProfiles ? "editable" : "locked"
        let reorderSummary = (0..<3)
            .compactMap { index in
                reorderState(for: index).map { "row\(index):\($0)" }
            }
            .joined(separator: "|")

        guard reorderSummary.isEmpty == false else { return editability }
        return "\(editability)|\(reorderSummary)"
    }

    var orderValue: String {
        profiles.map(\.name).joined(separator: "|")
    }

    var uiTestStateValue: String {
        "\(editabilityValue)||order:\(orderValue)"
    }
}
