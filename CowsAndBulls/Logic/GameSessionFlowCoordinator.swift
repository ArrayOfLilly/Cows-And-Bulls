//
//  GameSessionFlowCoordinator.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import Foundation

struct GameSessionFlowRuntime {
    let gameplayStore: GameplayStore
    let gameSessionStore: GameSessionStore
    let historyStore: HistoryStore
    let profileStore: ProfileStore
    let timerController: GameTimerController
}

@MainActor
enum GameSessionFlowCoordinator {
    static func startNewGame(
        settings: ProfileSettings,
        runtime: GameSessionFlowRuntime,
        hideVictoryCelebration: () -> Void,
        startTimeLimits: () -> Void,
        focusGuessField: () -> Void
    ) {
        GameCoordinator.startNewGame(
            settings: settings,
            gameplayStore: runtime.gameplayStore,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            hideVictoryCelebration: hideVictoryCelebration
        )
        guard runtime.gameplayStore.answer.isEmpty == false else { return }
        startTimeLimits()
        focusGuessField()
    }

    static func saveGameToHistory(
        runtime: GameSessionFlowRuntime,
        finalState: Bool,
        answer: String,
        guesses: [String],
        score: Int,
        settings: ProfileSettings,
        endReason: HistoryItem.EndReason = .completed
    ) {
        guard let item = runtime.gameSessionStore.makeHistoryItem(
            finalState: finalState,
            answer: answer,
            guesses: guesses,
            score: score,
            currentSettings: settings,
            endReason: endReason
        ) else {
            return
        }
        runtime.historyStore.add(item)
    }

    static func resetGameSession(
        runtime: GameSessionFlowRuntime,
        hideVictoryCelebration: () -> Void
    ) {
        GameCoordinator.resetGameSession(
            gameplayStore: runtime.gameplayStore,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            hideVictoryCelebration: hideVictoryCelebration
        )
    }

    static func togglePause(
        canTogglePause: Bool,
        isPaused: Bool,
        runtime: GameSessionFlowRuntime,
        resumeTimeLimitsAfterPause: () -> Void,
        focusGuessField: () -> Void
    ) {
        guard canTogglePause else { return }
        if isPaused {
            runtime.gameSessionStore.resume()
            resumeTimeLimitsAfterPause()
            focusGuessField()
        } else {
            runtime.timerController.stopAll()
            runtime.gameSessionStore.pause()
        }
    }

    static func pauseForWindowClose(
        canPauseForWindowClose: Bool,
        runtime: GameSessionFlowRuntime
    ) {
        guard canPauseForWindowClose else { return }
        runtime.timerController.stopAll()
        runtime.gameSessionStore.pause(dueToWindowClose: true)
    }

    static func resumeAfterWindowCloseIfNeeded(
        runtime: GameSessionFlowRuntime,
        isAnyTimerActive: Bool,
        resumeTimeLimitsAfterPause: () -> Void,
        focusGuessField: () -> Void
    ) {
        guard runtime.gameSessionStore.resumeAfterWindowCloseIfNeeded() else { return }
        if isAnyTimerActive {
            resumeTimeLimitsAfterPause()
        }
        focusGuessField()
    }

    static func endGameWithoutResult(runtime: GameSessionFlowRuntime) {
        runtime.timerController.stopAll()
        runtime.gameSessionStore.resetSession()
        runtime.gameplayStore.reset()
    }

    static func applyProfileSwitch(
        to profileId: String,
        runtime: GameSessionFlowRuntime,
        setLastSelectedProfileId: (String) -> Void,
        hideVictoryCelebration: () -> Void
    ) {
        runtime.profileStore.selectProfile(id: profileId)
        setLastSelectedProfileId(profileId)
        resetGameSession(runtime: runtime, hideVictoryCelebration: hideVictoryCelebration)
    }

    static func surrenderForProfileSwitch(
        hasGuesses: Bool,
        runtime: GameSessionFlowRuntime,
        saveSurrenderedGame: () -> Void,
        hideVictoryCelebration: () -> Void
    ) {
        GameCoordinator.surrenderForProfileSwitch(
            hasGuesses: hasGuesses,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            saveSurrenderedGame: saveSurrenderedGame,
            resetGameSession: {
                resetGameSession(runtime: runtime, hideVictoryCelebration: hideVictoryCelebration)
            }
        )
    }

    static func pauseGameForProfileSwitch(
        canPause: Bool,
        runtime: GameSessionFlowRuntime
    ) {
        GameCoordinator.pauseGameForProfileSwitch(
            canPause: canPause,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController
        )
    }
}
