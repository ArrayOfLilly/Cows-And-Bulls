//
//  GameRootSupport.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

enum GameRootBindings {
    static func profileSelection(
        profileStore: ProfileStore,
        presentationRules: GamePresentationRules,
        lastSelectedProfileId: String,
        sessionFlowRuntime: GameSessionFlowRuntime,
        callbacks: GameProfileSelectionCallbacks
    ) -> Binding<String> {
        Binding(
            get: { profileStore.selectedProfileId },
            set: { newValue in
                GameProfileSelectionCoordinator.handleSelection(
                    newValue,
                    decision: presentationRules.decisionForProfileSelection(
                        newValue,
                        newProfileSelectionId: ProfileStore.newProfileSelectionId
                    ),
                    profileStore: profileStore,
                    lastSelectedProfileId: lastSelectedProfileId,
                    sessionFlowRuntime: sessionFlowRuntime,
                    callbacks: callbacks
                )
            }
        )
    }

    static func guess(_ gameplayStore: GameplayStore) -> Binding<String> {
        Binding(
            get: { gameplayStore.guess },
            set: { gameplayStore.guess = $0 }
        )
    }

    static func isGameOver(_ gameplayStore: GameplayStore) -> Binding<Bool> {
        Binding(
            get: { gameplayStore.isGameOver },
            set: { gameplayStore.isGameOver = $0 }
        )
    }

    static func localBool(
        get: @escaping () -> Bool,
        set: @escaping (Bool) -> Void
    ) -> Binding<Bool> {
        Binding(get: get, set: set)
    }
}

struct GameRootWindowCloseConfiguration {
    let shouldPromptOnClose: () -> Bool
    let onPause: () -> Void
    let onGiveUp: () -> Void
    let onResume: () -> Void
}

struct GameRootNewProfileSheetActions {
    let onCreate: (String) -> Void
    let onCancel: () -> Void
}

enum GameRootAssemblies {
    static func windowCloseConfiguration(
        presentationRules: GamePresentationRules,
        onPause: @escaping () -> Void,
        onGiveUp: @escaping () -> Void,
        onResume: @escaping () -> Void
    ) -> GameRootWindowCloseConfiguration {
        GameRootWindowCloseConfiguration(
            shouldPromptOnClose: { presentationRules.shouldPromptOnClose },
            onPause: onPause,
            onGiveUp: onGiveUp,
            onResume: onResume
        )
    }

    static func newProfileSheetActions(
        profileStore: ProfileStore,
        callbacks: GameProfileCreationCallbacks
    ) -> GameRootNewProfileSheetActions {
        GameRootNewProfileSheetActions(
            onCreate: { name in
                GameProfileSelectionCoordinator.createProfile(
                    named: name,
                    profileStore: profileStore,
                    callbacks: callbacks
                )
            },
            onCancel: {
                GameProfileSelectionCoordinator.cancelProfileCreation(
                    callbacks: callbacks
                )
            }
        )
    }
}

struct GameRootSnapshot {
    let settings: ProfileSettings
    let answer: String
    let guesses: [String]
    let gameInProgress: Bool
    let isWon: Bool
    let isGameOver: Bool
    let guessInputErrorMessage: String
    let gameOverMessage: String
    let isDisabledSubmitButton: Bool
    let perGuessRemainingSeconds: Int
    let gameRemainingSeconds: Int
    let guessDurations: [Int]
    let timeoutEndReason: HistoryItem.EndReason?
    let isPaused: Bool
    let averageSteps: Double
    let bestWinStreak: Int

    init(
        settings: ProfileSettings,
        gameplayStore: GameplayStore,
        gameSessionStore: GameSessionStore,
        historyItems: [HistoryItem]
    ) {
        self.settings = settings
        answer = gameplayStore.answer
        guesses = gameplayStore.guesses
        gameInProgress = gameSessionStore.gameInProgress
        isWon = gameplayStore.isWon
        isGameOver = gameplayStore.isGameOver
        guessInputErrorMessage = gameplayStore.guessInputErrorMessage
        gameOverMessage = gameplayStore.gameOverMessage
        isDisabledSubmitButton = gameplayStore.isDisabledSubmitButton
        perGuessRemainingSeconds = gameSessionStore.perGuessRemainingSeconds
        gameRemainingSeconds = gameSessionStore.gameRemainingSeconds
        guessDurations = gameSessionStore.guessDurations
        timeoutEndReason = gameSessionStore.timeoutEndReason
        isPaused = gameSessionStore.isPaused

        let stats = StatisticsLogic(items: historyItems)
        averageSteps = stats.averageSteps
        bestWinStreak = stats.bestWinStreak
    }

    func presentationRules(startedSettingsSnapshot: GameplaySettingsSnapshot?) -> GamePresentationRules {
        GamePresentationRules(
            settings: settings,
            startedSettingsSnapshot: startedSettingsSnapshot,
            guessesCount: guesses.count,
            gameInProgress: gameInProgress,
            hasGuesses: guesses.isEmpty == false,
            isWon: isWon,
            isGameOver: isGameOver
        )
    }

    func makeGameTabContext(
        profiles: [PlayerProfile],
        profileSelection: Binding<String>,
        startedSettingsSnapshot: GameplaySettingsSnapshot?
    ) -> GameTabContext {
        let rules = presentationRules(startedSettingsSnapshot: startedSettingsSnapshot)

        return GameTabContext(
            header: GameHeaderContext(
                profiles: profiles,
                profileSelection: profileSelection,
                canChangeProfile: rules.canChangeProfile,
                profilePickerHelpText: rules.profilePickerHelpText,
                gameModeMessage: rules.gameModeMessage,
                averageSteps: averageSteps,
                bestWinStreak: bestWinStreak,
                selectedBullAssetName: settings.selectedBullAssetName,
                selectedCowAssetName: settings.selectedCowAssetName,
                isAnyTimerActive: rules.isAnyTimerActive,
                isPerGuessLimitActive: rules.isPerGuessLimitActive,
                isGameLimitActive: rules.isGameLimitActive,
                perGuessRemainingSeconds: perGuessRemainingSeconds,
                gameRemainingSeconds: gameRemainingSeconds,
                isPaused: isPaused
            ),
            input: GameInputContext(
                guessBinding: .constant(""),
                isPaused: isPaused,
                isDisabledSubmitButton: isDisabledSubmitButton,
                guessInputErrorMessage: guessInputErrorMessage
            ),
            guessesList: GuessesListContext(
                guesses: guesses,
                guessDurations: guessDurations,
                answer: answer,
                selectedBullAssetName: settings.selectedBullAssetName,
                selectedCowAssetName: settings.selectedCowAssetName
            ),
            footer: GameFooterContext(
                showGuessCount: settings.showGuessCount,
                guessesCount: guesses.count,
                maximumGuesses: settings.maximumGuesses,
                canSurrender: rules.canSurrender
            ),
            guess: "",
            guessesCount: guesses.count,
            scoreValue: rules.scoreValue,
            lossAlertMessage: rules.lossAlertMessage(answer: answer, gameOverMessage: gameOverMessage)
        )
    }

    var gameTurnFeedback: GameTurnFeedback {
        GameTurnFeedback(
            enableCelebration: settings.enableCelebration,
            soundEffectsEnabled: settings.enableSoundEffects,
            soundEffectsVolume: settings.soundEffectsVolume
        )
    }
}
