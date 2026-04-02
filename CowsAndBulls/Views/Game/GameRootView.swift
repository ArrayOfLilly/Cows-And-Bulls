//
//  GameRootView.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI
import AppKit

struct GameRootView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var settingsStore: ProfileSettingsStore
    @EnvironmentObject private var gameSessionStore: GameSessionStore
    @EnvironmentObject private var gameplayStore: GameplayStore
    @State private var timerController = GameTimerController()

    @State private var showSurrenderConfirmation = false
    @State private var showNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var lastSelectedProfileId = ""
    @State private var pendingProfileSwitchId: String?
    @State private var showProfileSwitchDialog = false
    @State private var showWinAlert = false

    @FocusState private var isGuessFieldFocused: Bool

    private var settings: ProfileSettings { settingsStore.settings }
    private var gameInProgress: Bool { gameSessionStore.gameInProgress }
    private var answer: String { gameplayStore.answer }
    private var guesses: [String] { gameplayStore.guesses }
    private var guess: String {
        get { gameplayStore.guess }
        nonmutating set { gameplayStore.guess = newValue }
    }
    private var isWon: Bool {
        get { gameplayStore.isWon }
        nonmutating set { gameplayStore.isWon = newValue }
    }
    private var isGameOver: Bool {
        get { gameplayStore.isGameOver }
        nonmutating set { gameplayStore.isGameOver = newValue }
    }
    private var isDisabledSubmitButton: Bool { gameplayStore.isDisabledSubmitButton }
    private var guessInputErrorMessage: String { gameplayStore.guessInputErrorMessage }
    private var gameOverMessage: String { gameplayStore.gameOverMessage }
    private var perGuessRemainingSeconds: Int { gameSessionStore.perGuessRemainingSeconds }
    private var gameRemainingSeconds: Int { gameSessionStore.gameRemainingSeconds }
    private var guessDurations: [Int] { gameSessionStore.guessDurations }
    private var timeoutEndReason: HistoryItem.EndReason? { gameSessionStore.timeoutEndReason }
    private var isPaused: Bool { gameSessionStore.isPaused }
    private var maximumGuesses: Int { settings.maximumGuesses }
    private var showGuessCount: Bool { settings.showGuessCount }
    private var enableCelebration: Bool { settings.enableCelebration }
    private var enableSoundEffects: Bool { settings.enableSoundEffects }
    private var soundEffectsVolume: Double { settings.soundEffectsVolume }
    private var perGuessTimeLimitSeconds: Int { settings.perGuessTimeLimitSeconds }
    private var selectedBullAssetName: String { settings.selectedBullAssetName }
    private var selectedCowAssetName: String { settings.selectedCowAssetName }

    private var stats: StatisticsLogic {
        StatisticsLogic(items: historyStore.items)
    }

    private var presentationRules: GamePresentationRules {
        GamePresentationRules(
            settings: settings,
            startedSettingsSnapshot: gameSessionStore.startedSettingsSnapshot,
            guessesCount: guesses.count,
            gameInProgress: gameInProgress,
            hasGuesses: guesses.isEmpty == false,
            isWon: isWon,
            isGameOver: isGameOver
        )
    }

    private var scoreValue: Int { presentationRules.scoreValue }
    private var isPerGuessLimitActive: Bool { presentationRules.isPerGuessLimitActive }
    private var isGameLimitActive: Bool { presentationRules.isGameLimitActive }
    private var isAnyTimerActive: Bool { presentationRules.isAnyTimerActive }
    private var canChangeProfile: Bool { presentationRules.canChangeProfile }

    private var gameHeaderContext: GameHeaderContext {
        GameHeaderContext(
            profiles: profileStore.profiles,
            profileSelection: profileSelection,
            canChangeProfile: canChangeProfile,
            profilePickerHelpText: presentationRules.profilePickerHelpText,
            gameModeMessage: gameModeMessage,
            averageSteps: stats.averageSteps,
            bestWinStreak: stats.bestWinStreak,
            selectedBullAssetName: selectedBullAssetName,
            selectedCowAssetName: selectedCowAssetName,
            isAnyTimerActive: isAnyTimerActive,
            isPerGuessLimitActive: isPerGuessLimitActive,
            isGameLimitActive: isGameLimitActive,
            perGuessRemainingSeconds: perGuessRemainingSeconds,
            gameRemainingSeconds: gameRemainingSeconds,
            isPaused: isPaused
        )
    }

    private var gameInputContext: GameInputContext {
        GameInputContext(
            guessBinding: guessBinding,
            isPaused: isPaused,
            isDisabledSubmitButton: isDisabledSubmitButton,
            guessInputErrorMessage: guessInputErrorMessage
        )
    }

    private var guessesListContext: GuessesListContext {
        GuessesListContext(
            guesses: guesses,
            guessDurations: guessDurations,
            answer: answer,
            selectedBullAssetName: selectedBullAssetName,
            selectedCowAssetName: selectedCowAssetName
        )
    }

    private var gameFooterContext: GameFooterContext {
        GameFooterContext(
            showGuessCount: showGuessCount,
            guessesCount: guesses.count,
            maximumGuesses: maximumGuesses,
            canSurrender: presentationRules.canSurrender
        )
    }

    private var gameTabContext: GameTabContext {
        GameTabContext(
            header: gameHeaderContext,
            input: gameInputContext,
            guessesList: guessesListContext,
            footer: gameFooterContext,
            guess: guess,
            guessesCount: guesses.count,
            scoreValue: scoreValue,
            lossAlertMessage: presentationRules.lossAlertMessage(answer: answer, gameOverMessage: gameOverMessage)
        )
    }

    private var gameTabActions: GameTabActions {
        GameTabActions(
            onAppear: {
                if answer.isEmpty {
                    resetGameSession()
                }
            },
            onDisappear: hideVictoryCelebration,
            onGuessChange: {
                if gameInProgress == false, guess.isEmpty == false {
                    let pendingGuess = guess
                    GameSessionFlowCoordinator.startNewGame(
                        settings: settings,
                        runtime: sessionFlowRuntime,
                        hideVictoryCelebration: hideVictoryCelebration,
                        startTimeLimits: startTimeLimits,
                        focusGuessField: { focusGuessField() }
                    )
                    guess = pendingGuess
                }
                gameplayStore.updateLiveGuessValidation(settings: settings)
            },
            onTogglePause: {
                GameSessionFlowCoordinator.togglePause(
                    canTogglePause: presentationRules.canTogglePause,
                    isPaused: isPaused,
                    runtime: sessionFlowRuntime,
                    resumeTimeLimitsAfterPause: resumeTimeLimitsAfterPause,
                    focusGuessField: { focusGuessField() }
                )
            },
            onSubmitGuess: {
                let result = gameplayStore.submitGuess(settings: settings, gameInProgress: gameInProgress)

                if result == .invalid {
                    focusGuessField(selectAll: true)
                    return
                }

                gameSessionStore.recordSubmittedGuess()
                GameTurnCoordinator.handleSubmissionResult(
                    result,
                    runtime: gameTurnRuntime,
                    feedback: gameTurnFeedback,
                    handlers: GameTurnHandlers(
                        restartPerGuessTimeLimit: restartPerGuessTimeLimit,
                        playVictoryCelebration: playVictoryCelebration,
                        showWinAlert: {
                            isWon = true
                            showWinAlert = true
                        },
                        endGameWithoutResult: endGameWithoutResult
                    ),
                    playSound: { effect, enabled, volume in
                        SoundPlayer.shared.play(effect, enabled: enabled, volume: volume)
                    }
                )

                focusGuessField()
            },
            onSurrender: {
                guard gameInProgress, guesses.isEmpty == false, isWon == false, isGameOver == false else { return }
                GameTurnCoordinator.surrenderGame(
                    runtime: gameTurnRuntime,
                    presentation: gameTurnPresentation(guessesAreEmpty: guesses.isEmpty),
                    feedback: gameTurnFeedback,
                    playSound: { effect, enabled, volume in
                        SoundPlayer.shared.play(effect, enabled: enabled, volume: volume)
                    }
                )
            },
            onConfirmProfileSwitchSurrender: {
                GameSessionFlowCoordinator.surrenderForProfileSwitch(
                    hasGuesses: guesses.isEmpty == false,
                    runtime: sessionFlowRuntime,
                    saveSurrenderedGame: {
                        saveGameToHistory(finalState: false, score: 0, endReason: .surrender)
                    },
                    hideVictoryCelebration: hideVictoryCelebration
                )
                if let pendingProfileSwitchId {
                    GameSessionFlowCoordinator.applyProfileSwitch(
                        to: pendingProfileSwitchId,
                        runtime: sessionFlowRuntime,
                        setLastSelectedProfileId: { lastSelectedProfileId = $0 },
                        hideVictoryCelebration: hideVictoryCelebration
                    )
                }
            },
            onConfirmProfileSwitchPause: {
                GameSessionFlowCoordinator.pauseGameForProfileSwitch(
                    canPause: gameInProgress && isWon == false && isGameOver == false,
                    runtime: sessionFlowRuntime
                )
            },
            onWinPlayAgain: {
                hideVictoryCelebration()
                showWinAlert = false
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
                GameSessionFlowCoordinator.startNewGame(
                    settings: settings,
                    runtime: sessionFlowRuntime,
                    hideVictoryCelebration: hideVictoryCelebration,
                    startTimeLimits: startTimeLimits,
                    focusGuessField: { focusGuessField() }
                )
            },
            onWinAcknowledge: {
                hideVictoryCelebration()
                showWinAlert = false
                gameplayStore.finalizeWin()
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
            },
            onLossPlayAgain: {
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
                GameSessionFlowCoordinator.startNewGame(
                    settings: settings,
                    runtime: sessionFlowRuntime,
                    hideVictoryCelebration: hideVictoryCelebration,
                    startTimeLimits: startTimeLimits,
                    focusGuessField: { focusGuessField() }
                )
            },
            onLossAcknowledge: {
                gameplayStore.finalizeLoss()
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
            },
            onRestart: {
                GameSessionFlowCoordinator.startNewGame(
                    settings: settings,
                    runtime: sessionFlowRuntime,
                    hideVictoryCelebration: hideVictoryCelebration,
                    startTimeLimits: startTimeLimits,
                    focusGuessField: { focusGuessField() }
                )
            }
        )
    }

    private var gameTurnRuntime: GameTurnRuntime {
        GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            timerController: timerController
        )
    }

    private var sessionFlowRuntime: GameSessionFlowRuntime {
        GameSessionFlowRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            historyStore: historyStore,
            profileStore: profileStore,
            timerController: timerController
        )
    }

    private var gameTurnFeedback: GameTurnFeedback {
        GameTurnFeedback(
            enableCelebration: enableCelebration,
            soundEffectsEnabled: enableSoundEffects,
            soundEffectsVolume: soundEffectsVolume
        )
    }

    private func gameTurnPresentation(guessesAreEmpty: Bool) -> GameTurnPresentation {
        GameTurnPresentation(
            guessesAreEmpty: guessesAreEmpty,
            timeoutMessage: { type in
                presentationRules.timeoutGameOverMessage(
                    for: type == .perGuess ? .perGuess : .game,
                    answer: answer
                )
            },
            surrenderMessage: {
                presentationRules.surrenderGameOverMessage(answer: answer)
            }
        )
    }

    private var profileSelection: Binding<String> {
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
                    setShowNewProfileSheet: { showNewProfileSheet = $0 },
                    setPendingProfileSwitchId: { pendingProfileSwitchId = $0 },
                    setShowProfileSwitchDialog: { showProfileSwitchDialog = $0 },
                    setLastSelectedProfileId: { lastSelectedProfileId = $0 },
                    hideVictoryCelebration: hideVictoryCelebration
                )
            }
        )
    }

    private var guessBinding: Binding<String> {
        Binding(
            get: { gameplayStore.guess },
            set: { gameplayStore.guess = $0 }
        )
    }

    private var isGameOverBinding: Binding<Bool> {
        Binding(
            get: { gameplayStore.isGameOver },
            set: { gameplayStore.isGameOver = $0 }
        )
    }

    private var showWinAlertBinding: Binding<Bool> {
        Binding(
            get: { showWinAlert },
            set: { showWinAlert = $0 }
        )
    }

    private var gameModeMessage: String { presentationRules.gameModeMessage }

    private func saveGameToHistory(finalState: Bool, score: Int, endReason: HistoryItem.EndReason = .completed) {
        GameSessionFlowCoordinator.saveGameToHistory(
            runtime: sessionFlowRuntime,
            finalState: finalState,
            answer: answer,
            guesses: guesses,
            score: score,
            settings: settings,
            endReason: endReason
        )
    }

    private func startTimeLimits() {
        GameTimeLimitCoordinator.start(
            timerController: timerController,
            gameSessionStore: gameSessionStore,
            perGuessActive: isPerGuessLimitActive,
            gameActive: isGameLimitActive,
            onExpire: handleTimeLimitExpired
        )
    }

    private func resumeTimeLimitsAfterPause() {
        startTimeLimits()
    }

    private func handleTimeLimitExpired(_ type: GameTimeLimitType) {
        GameTurnCoordinator.handleTimeLimitExpired(
            type,
            runtime: gameTurnRuntime,
            presentation: gameTurnPresentation(guessesAreEmpty: guesses.isEmpty),
            feedback: gameTurnFeedback,
            playSound: { effect, enabled, volume in
                SoundPlayer.shared.play(effect, enabled: enabled, volume: volume)
            }
        )
    }

    private func restartPerGuessTimeLimit() {
        GameTimeLimitCoordinator.restartPerGuess(
            timerController: timerController,
            gameSessionStore: gameSessionStore,
            isActive: isPerGuessLimitActive,
            seconds: perGuessTimeLimitSeconds,
            onExpire: handleTimeLimitExpired
        )
    }

    private func pauseForWindowClose() {
        GameSessionFlowCoordinator.pauseForWindowClose(
            canPauseForWindowClose: presentationRules.canPauseForWindowClose,
            runtime: sessionFlowRuntime
        )
    }

    private func resumeAfterWindowCloseIfNeeded() {
        GameSessionFlowCoordinator.resumeAfterWindowCloseIfNeeded(
            runtime: sessionFlowRuntime,
            isAnyTimerActive: isAnyTimerActive,
            resumeTimeLimitsAfterPause: resumeTimeLimitsAfterPause,
            focusGuessField: { focusGuessField() }
        )
    }

    private func endGameWithoutResult() {
        GameSessionFlowCoordinator.endGameWithoutResult(runtime: sessionFlowRuntime)
    }

    private func resetGameSession() {
        GameSessionFlowCoordinator.resetGameSession(
            runtime: sessionFlowRuntime,
            hideVictoryCelebration: hideVictoryCelebration
        )
    }

    private func focusGuessField(selectAll: Bool = false) {
        ContentViewPresentationCoordinator.focusGuessField(
            setFocused: { isGuessFieldFocused = true },
            selectAll: selectAll
        )
    }

    private func playVictoryCelebration() {
        showWinAlert = false
        ContentViewPresentationCoordinator.playVictoryCelebration {
            isWon = true
            showWinAlert = true
        }
    }

    private func hideVictoryCelebration() {
        ContentViewPresentationCoordinator.hideVictoryCelebration()
    }

    var body: some View {
        GameTabView(
            context: gameTabContext,
            actions: gameTabActions,
            showSurrenderConfirmation: $showSurrenderConfirmation,
            pendingProfileSwitchId: $pendingProfileSwitchId,
            showProfileSwitchDialog: $showProfileSwitchDialog,
            showWinAlert: showWinAlertBinding,
            isGameOver: isGameOverBinding,
            focusBinding: $isGuessFieldFocused
        )
        .onAppear {
            if lastSelectedProfileId.isEmpty {
                lastSelectedProfileId = profileStore.selectedProfileId
            }
        }
        .background(
            WindowCloseHandler(
                shouldPromptOnClose: {
                    presentationRules.shouldPromptOnClose
                },
                onPause: {
                    pauseForWindowClose()
                },
                onGiveUp: gameTabActions.onSurrender,
                onResume: {
                    resumeAfterWindowCloseIfNeeded()
                }
            )
        )
        .onChange(of: profileStore.selectedProfileId) {
            lastSelectedProfileId = profileStore.selectedProfileId
        }
        .sheet(isPresented: $showNewProfileSheet) {
            NewProfileSheet(
                name: $newProfileName,
                onCreate: { name in
                    GameProfileSelectionCoordinator.createProfile(
                        named: name,
                        profileStore: profileStore,
                        clearName: { newProfileName = "" },
                        dismissSheet: { showNewProfileSheet = false }
                    )
                },
                onCancel: {
                    GameProfileSelectionCoordinator.cancelProfileCreation(
                        clearName: { newProfileName = "" },
                        dismissSheet: { showNewProfileSheet = false }
                    )
                }
            )
        }
    }
}
