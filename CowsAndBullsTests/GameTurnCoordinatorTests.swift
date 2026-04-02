//
//  GameTurnCoordinatorTests.swift
//  CowsAndBullsTests
//
//  Created by Ildikó Kasza.
//

import Testing
@testable import Cows___Bulls

@MainActor
struct GameTurnCoordinatorTests {
    @Test("Won submission without celebration finishes the game and requests a win alert")
    func wonSubmissionShowsAlertWhenCelebrationDisabled() {
        let gameplayStore = GameplayStore()
        let sessionStore = GameSessionStore()
        let timerController = GameTimerController()
        sessionStore.beginGame(with: .default)

        let runtime = GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: sessionStore,
            timerController: timerController
        )
        let feedback = GameTurnFeedback(
            enableCelebration: false,
            soundEffectsEnabled: true,
            soundEffectsVolume: 0.4
        )

        var showedWinAlert = false
        var playedEffects: [SoundPlayer.Effect] = []

        GameTurnCoordinator.handleSubmissionResult(
            .won,
            runtime: runtime,
            feedback: feedback,
            handlers: GameTurnHandlers(
                restartPerGuessTimeLimit: {},
                playVictoryCelebration: {},
                showWinAlert: { showedWinAlert = true },
                endGameWithoutResult: {}
            ),
            playSound: { effect, _, _ in
                playedEffects.append(effect)
            }
        )

        #expect(sessionStore.gameInProgress == false)
        #expect(gameplayStore.isWon == true)
        #expect(showedWinAlert)
        #expect(playedEffects == [.win])
    }

    @Test("Submitted guess restarts the per-guess timer and plays the submit sound")
    func submittedGuessRestartsPerGuessTimer() {
        let runtime = GameTurnRuntime(
            gameplayStore: GameplayStore(),
            gameSessionStore: GameSessionStore(),
            timerController: GameTimerController()
        )
        let feedback = GameTurnFeedback(
            enableCelebration: false,
            soundEffectsEnabled: true,
            soundEffectsVolume: 0.4
        )

        var restartedTimer = false
        var playedEffects: [SoundPlayer.Effect] = []

        GameTurnCoordinator.handleSubmissionResult(
            .submitted,
            runtime: runtime,
            feedback: feedback,
            handlers: GameTurnHandlers(
                restartPerGuessTimeLimit: { restartedTimer = true },
                playVictoryCelebration: {},
                showWinAlert: {},
                endGameWithoutResult: {}
            ),
            playSound: { effect, _, _ in
                playedEffects.append(effect)
            }
        )

        #expect(restartedTimer)
        #expect(playedEffects == [.submit])
    }

    @Test("Timeout without guesses resets the round without presenting a game-over state")
    func timeoutWithoutGuessesResetsRound() {
        let gameplayStore = GameplayStore()
        let sessionStore = GameSessionStore()
        let timerController = GameTimerController()
        var settings = ProfileSettings.default
        settings.enablePerGuessTimeLimit = true
        settings.perGuessTimeLimitSeconds = 5

        gameplayStore.startNewGame(settings: settings)
        sessionStore.beginGame(with: settings)

        let runtime = GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: sessionStore,
            timerController: timerController
        )
        let feedback = GameTurnFeedback(
            enableCelebration: false,
            soundEffectsEnabled: true,
            soundEffectsVolume: 0.4
        )

        GameTurnCoordinator.handleTimeLimitExpired(
            .perGuess,
            runtime: runtime,
            presentation: GameTurnPresentation(
                guessesAreEmpty: true,
                timeoutMessage: { _ in "unused" },
                surrenderMessage: { "unused" }
            ),
            feedback: feedback,
            playSound: { _, _, _ in
                Issue.record("No sound should be played when the round resets without a guess")
            }
        )

        #expect(sessionStore.gameInProgress == false)
        #expect(gameplayStore.answer.isEmpty)
        #expect(gameplayStore.isGameOver == false)
    }

    @Test("Surrender presents a loss state and records surrender")
    func surrenderPresentsLossState() {
        let gameplayStore = GameplayStore()
        let sessionStore = GameSessionStore()
        let timerController = GameTimerController()
        gameplayStore.startNewGame(settings: .default)
        sessionStore.beginGame(with: .default)

        let runtime = GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: sessionStore,
            timerController: timerController
        )
        let feedback = GameTurnFeedback(
            enableCelebration: false,
            soundEffectsEnabled: true,
            soundEffectsVolume: 0.4
        )

        var playedEffects: [SoundPlayer.Effect] = []

        GameTurnCoordinator.surrenderGame(
            runtime: runtime,
            presentation: GameTurnPresentation(
                guessesAreEmpty: false,
                timeoutMessage: { _ in "unused" },
                surrenderMessage: { "Surrendered" }
            ),
            feedback: feedback,
            playSound: { effect, _, _ in
                playedEffects.append(effect)
            }
        )

        #expect(sessionStore.timeoutEndReason == .surrender)
        #expect(gameplayStore.isGameOver == true)
        #expect(gameplayStore.gameOverMessage == "Surrendered")
        #expect(playedEffects == [.lose])
    }
}
