//
//  GameTurnCoordinator.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

struct GameTurnRuntime {
    let gameplayStore: GameplayStore
    let gameSessionStore: GameSessionStore
    let timerController: GameTimerController
}

struct GameTurnFeedback {
    let enableCelebration: Bool
    let soundEffectsEnabled: Bool
    let soundEffectsVolume: Double
}

struct GameTurnPresentation {
    let guessesAreEmpty: Bool
    let timeoutMessage: (GameTimeLimitType) -> String
    let surrenderMessage: () -> String
}

struct GameTurnHandlers {
    let restartPerGuessTimeLimit: () -> Void
    let playVictoryCelebration: () -> Void
    let showWinAlert: () -> Void
    let endGameWithoutResult: () -> Void
}

@MainActor
enum GameTurnCoordinator {
    static func handleSubmissionResult(
        _ result: GameplayStore.SubmissionResult,
        runtime: GameTurnRuntime,
        feedback: GameTurnFeedback,
        handlers: GameTurnHandlers,
        playSound: (SoundPlayer.Effect, Bool, Double) -> Void
    ) {
        switch result {
        case .invalid:
            return
        case .submitted:
            playSound(.submit, feedback.soundEffectsEnabled, feedback.soundEffectsVolume)
            handlers.restartPerGuessTimeLimit()
        case .won:
            runtime.timerController.stopAll()
            runtime.gameSessionStore.finishGame()
            playSound(.win, feedback.soundEffectsEnabled, feedback.soundEffectsVolume)
            if feedback.enableCelebration {
                handlers.playVictoryCelebration()
            } else {
                runtime.gameplayStore.isWon = true
                handlers.showWinAlert()
            }
        case .lost:
            runtime.timerController.stopAll()
            runtime.gameSessionStore.finishGame()
            playSound(.lose, feedback.soundEffectsEnabled, feedback.soundEffectsVolume)
            runtime.gameplayStore.isGameOver = true
        }
    }

    static func handleTimeLimitExpired(
        _ type: GameTimeLimitType,
        runtime: GameTurnRuntime,
        presentation: GameTurnPresentation,
        feedback: GameTurnFeedback,
        playSound: (SoundPlayer.Effect, Bool, Double) -> Void
    ) {
        runtime.timerController.stopAll()
        runtime.gameSessionStore.markTimeout(type == .perGuess ? .timeoutPerGuess : .timeoutGame)
        if presentation.guessesAreEmpty {
            handlersForEmptyTimeout(runtime: runtime).endGameWithoutResult()
            return
        }
        runtime.gameplayStore.presentGameOver(message: presentation.timeoutMessage(type))
        playSound(.lose, feedback.soundEffectsEnabled, feedback.soundEffectsVolume)
    }

    static func surrenderGame(
        runtime: GameTurnRuntime,
        presentation: GameTurnPresentation,
        feedback: GameTurnFeedback,
        playSound: (SoundPlayer.Effect, Bool, Double) -> Void
    ) {
        runtime.timerController.stopAll()
        runtime.gameSessionStore.markSurrender()
        runtime.gameplayStore.presentGameOver(message: presentation.surrenderMessage())
        playSound(.lose, feedback.soundEffectsEnabled, feedback.soundEffectsVolume)
    }

    private static func handlersForEmptyTimeout(runtime: GameTurnRuntime) -> GameTurnHandlers {
        GameTurnHandlers(
            restartPerGuessTimeLimit: {},
            playVictoryCelebration: {},
            showWinAlert: {},
            endGameWithoutResult: {
                runtime.timerController.stopAll()
                runtime.gameSessionStore.resetSession()
                runtime.gameplayStore.reset()
            }
        )
    }
}
