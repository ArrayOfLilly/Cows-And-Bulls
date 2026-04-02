//
//  ContentViewPresentationCoordinator.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI
import AppKit

@MainActor
enum ContentViewPresentationCoordinator {
    static func focusGuessField(
        setFocused: @escaping () -> Void,
        selectAll: Bool = false
    ) {
        DispatchQueue.main.async {
            setFocused()
            if selectAll {
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }
        }
    }

    static func playVictoryCelebration(
        showWinAlert: @escaping () -> Void
    ) {
        VictoryCelebrationWindowController.shared.present(from: NSApp.keyWindow ?? NSApp.mainWindow) {
            showWinAlert()
        }
    }

    static func hideVictoryCelebration() {
        VictoryCelebrationWindowController.shared.dismiss()
    }
}
