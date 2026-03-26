//
//  GameCoordinatorTests.swift
//  CowsAndBullsTests
//
//  Created by Codex on 2026. 03. 18..
//

import Testing
import Foundation
@testable import Cows___Bulls

@MainActor
struct GameCoordinatorTests {
    @Test("Start new game resets state and begins a fresh session")
    func startNewGameBeginsSession() {
        let gameplayStore = GameplayStore()
        let sessionStore = GameSessionStore()
        let timerController = GameTimerController()

        gameplayStore.guess = "1234"
        gameplayStore.isGameOver = true

        GameCoordinator.startNewGame(
            settings: .default,
            gameplayStore: gameplayStore,
            gameSessionStore: sessionStore,
            timerController: timerController,
            hideVictoryCelebration: {}
        )

        #expect(gameplayStore.answer.isEmpty == false)
        #expect(sessionStore.gameInProgress)
        #expect(gameplayStore.isGameOver == false)
    }

    @Test("Reset game session clears both stores")
    func resetGameSessionClearsStores() {
        let gameplayStore = GameplayStore()
        let sessionStore = GameSessionStore()
        let timerController = GameTimerController()

        gameplayStore.startNewGame(settings: .default)
        sessionStore.beginGame(with: .default)

        GameCoordinator.resetGameSession(
            gameplayStore: gameplayStore,
            gameSessionStore: sessionStore,
            timerController: timerController,
            hideVictoryCelebration: {}
        )

        #expect(gameplayStore.answer.isEmpty)
        #expect(sessionStore.gameInProgress == false)
    }
}
