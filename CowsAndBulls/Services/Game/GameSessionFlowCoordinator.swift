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

struct GameSessionFlowCallbacks {
    let hideVictoryCelebration: () -> Void
    let startTimeLimits: () -> Void
    let resumeTimeLimitsAfterPause: () -> Void
    let focusGuessField: () -> Void
}

struct GameProfileSwitchCallbacks {
    let setLastSelectedProfileId: (String) -> Void
    let saveSurrenderedGame: () -> Void
    let hideVictoryCelebration: () -> Void
}

@MainActor
enum GameSessionFlowCoordinator {
    static func startNewGame(
        settings: ProfileSettings,
        runtime: GameSessionFlowRuntime,
        callbacks: GameSessionFlowCallbacks
    ) {
        GameCoordinator.startNewGame(
            settings: settings,
            gameplayStore: runtime.gameplayStore,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            hideVictoryCelebration: callbacks.hideVictoryCelebration
        )
        guard runtime.gameplayStore.answer.isEmpty == false else { return }
        callbacks.startTimeLimits()
        callbacks.focusGuessField()
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
        callbacks: GameSessionFlowCallbacks
    ) {
        GameCoordinator.resetGameSession(
            gameplayStore: runtime.gameplayStore,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            hideVictoryCelebration: callbacks.hideVictoryCelebration
        )
    }

    static func togglePause(
        canTogglePause: Bool,
        isPaused: Bool,
        runtime: GameSessionFlowRuntime,
        callbacks: GameSessionFlowCallbacks
    ) {
        guard canTogglePause else { return }
        if isPaused {
            runtime.gameSessionStore.resume()
            callbacks.resumeTimeLimitsAfterPause()
            callbacks.focusGuessField()
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
        callbacks: GameSessionFlowCallbacks
    ) {
        guard runtime.gameSessionStore.resumeAfterWindowCloseIfNeeded() else { return }
        if isAnyTimerActive {
            callbacks.resumeTimeLimitsAfterPause()
        }
        callbacks.focusGuessField()
    }

    static func endGameWithoutResult(runtime: GameSessionFlowRuntime) {
        runtime.timerController.stopAll()
        runtime.gameSessionStore.resetSession()
        runtime.gameplayStore.reset()
    }

    static func applyProfileSwitch(
        to profileId: String,
        runtime: GameSessionFlowRuntime,
        callbacks: GameProfileSwitchCallbacks
    ) {
        runtime.profileStore.selectProfile(id: profileId)
        callbacks.setLastSelectedProfileId(profileId)
        resetGameSession(
            runtime: runtime,
            callbacks: GameSessionFlowCallbacks(
                hideVictoryCelebration: callbacks.hideVictoryCelebration,
                startTimeLimits: {},
                resumeTimeLimitsAfterPause: {},
                focusGuessField: {}
            )
        )
    }

    static func surrenderForProfileSwitch(
        hasGuesses: Bool,
        runtime: GameSessionFlowRuntime,
        callbacks: GameProfileSwitchCallbacks
    ) {
        GameCoordinator.surrenderForProfileSwitch(
            hasGuesses: hasGuesses,
            gameSessionStore: runtime.gameSessionStore,
            timerController: runtime.timerController,
            saveSurrenderedGame: callbacks.saveSurrenderedGame,
            resetGameSession: {
                resetGameSession(
                    runtime: runtime,
                    callbacks: GameSessionFlowCallbacks(
                        hideVictoryCelebration: callbacks.hideVictoryCelebration,
                        startTimeLimits: {},
                        resumeTimeLimitsAfterPause: {},
                        focusGuessField: {}
                    )
                )
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
