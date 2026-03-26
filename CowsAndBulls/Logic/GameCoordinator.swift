//
//  GameCoordinator.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import Foundation

@MainActor
struct GameCoordinator {
    static func resetGameSession(
        gameplayStore: GameplayStore,
        gameSessionStore: GameSessionStore,
        timerController: GameTimerController,
        hideVictoryCelebration: () -> Void
    ) {
        hideVictoryCelebration()
        timerController.stopAll()
        gameSessionStore.resetSession()
        gameplayStore.reset()
    }

    static func startNewGame(
        settings: ProfileSettings,
        gameplayStore: GameplayStore,
        gameSessionStore: GameSessionStore,
        timerController: GameTimerController,
        hideVictoryCelebration: () -> Void
    ) {
        hideVictoryCelebration()
        timerController.stopAll()
        gameSessionStore.resetSession()
        gameplayStore.startNewGame(settings: settings)
        guard gameplayStore.answer.isEmpty == false else { return }
        gameSessionStore.beginGame(with: settings)
    }

    static func surrenderForProfileSwitch(
        hasGuesses: Bool,
        gameSessionStore: GameSessionStore,
        timerController: GameTimerController,
        saveSurrenderedGame: () -> Void,
        resetGameSession: () -> Void
    ) {
        guard hasGuesses else {
            resetGameSession()
            return
        }
        timerController.stopAll()
        gameSessionStore.markSurrender()
        saveSurrenderedGame()
        resetGameSession()
    }

    static func pauseGameForProfileSwitch(
        canPause: Bool,
        gameSessionStore: GameSessionStore,
        timerController: GameTimerController
    ) {
        guard canPause else { return }
        timerController.stopAll()
        gameSessionStore.pause()
    }
}
