//
//  GameRootView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI
import AppKit

struct GameRootView: View {
    private let soundEffectPlayer: any SoundEffectPlaying

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

    init(soundEffectPlayer: any SoundEffectPlaying = SoundPlayer.shared) {
        self.soundEffectPlayer = soundEffectPlayer
    }

    private var snapshot: GameRootSnapshot {
        GameRootSnapshot(
            settings: settingsStore.settings,
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            historyItems: historyStore.items
        )
    }

    private var settings: ProfileSettings { snapshot.settings }
    private var dependencies: GameDependencies {
        GameDependencies(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            historyStore: historyStore,
            profileStore: profileStore,
            timerController: timerController,
            soundEffectPlayer: soundEffectPlayer
        )
    }
    private var gameInProgress: Bool { snapshot.gameInProgress }
    private var answer: String { snapshot.answer }
    private var guesses: [String] { snapshot.guesses }
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
    private var timeoutEndReason: HistoryItem.EndReason? { snapshot.timeoutEndReason }
    private var isPaused: Bool { snapshot.isPaused }
    private var perGuessTimeLimitSeconds: Int { settings.perGuessTimeLimitSeconds }
    private var selectedBullAssetName: String { settings.selectedBullAssetName }
    private var selectedCowAssetName: String { settings.selectedCowAssetName }

    private var presentationRules: GamePresentationRules {
        snapshot.presentationRules(startedSettingsSnapshot: gameSessionStore.startedSettingsSnapshot)
    }

    private var scoreValue: Int { presentationRules.scoreValue }
    private var isPerGuessLimitActive: Bool { presentationRules.isPerGuessLimitActive }
    private var isGameLimitActive: Bool { presentationRules.isGameLimitActive }
    private var isAnyTimerActive: Bool { presentationRules.isAnyTimerActive }
    private var canChangeProfile: Bool { presentationRules.canChangeProfile }

    private var gameInputContext: GameInputContext {
        GameInputContext(
            guessBinding: guessBinding,
            isPaused: isPaused,
            isDisabledSubmitButton: snapshot.isDisabledSubmitButton,
            guessInputErrorMessage: snapshot.guessInputErrorMessage
        )
    }

    private var gameTabContext: GameTabContext {
        var context = snapshot.makeGameTabContext(
            profiles: profileStore.profiles,
            profileSelection: profileSelection,
            startedSettingsSnapshot: gameSessionStore.startedSettingsSnapshot
        )
        context = GameTabContext(
            header: context.header,
            input: GameInputContext(
                guessBinding: guessBinding,
                isPaused: context.input.isPaused,
                isDisabledSubmitButton: context.input.isDisabledSubmitButton,
                guessInputErrorMessage: context.input.guessInputErrorMessage
            ),
            guessesList: context.guessesList,
            footer: context.footer,
            guess: guess,
            guessesCount: context.guessesCount,
            scoreValue: context.scoreValue,
            lossAlertMessage: context.lossAlertMessage
        )
        return context
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
                        runtime: dependencies.sessionFlowRuntime,
                        callbacks: sessionFlowCallbacks
                    )
                    guess = pendingGuess
                }
                gameplayStore.updateLiveGuessValidation(settings: settings)
            },
            onTogglePause: {
                GameSessionFlowCoordinator.togglePause(
                    canTogglePause: presentationRules.canTogglePause,
                    isPaused: isPaused,
                    runtime: dependencies.sessionFlowRuntime,
                    callbacks: sessionFlowCallbacks
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
                    runtime: dependencies.turnRuntime,
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
                    playSound: playSoundEffect
                )

                focusGuessField()
            },
            onSurrender: {
                guard gameInProgress, guesses.isEmpty == false, isWon == false, isGameOver == false else { return }
                GameTurnCoordinator.surrenderGame(
                    runtime: dependencies.turnRuntime,
                    presentation: gameTurnPresentation(guessesAreEmpty: guesses.isEmpty),
                    feedback: gameTurnFeedback,
                    playSound: playSoundEffect
                )
            },
            onConfirmProfileSwitchSurrender: {
                GameSessionFlowCoordinator.surrenderForProfileSwitch(
                    hasGuesses: guesses.isEmpty == false,
                    runtime: dependencies.sessionFlowRuntime,
                    callbacks: profileSwitchCallbacks
                )
                if let pendingProfileSwitchId {
                    GameSessionFlowCoordinator.applyProfileSwitch(
                        to: pendingProfileSwitchId,
                        runtime: dependencies.sessionFlowRuntime,
                        callbacks: profileSwitchCallbacks
                    )
                }
            },
            onConfirmProfileSwitchPause: {
                GameSessionFlowCoordinator.pauseGameForProfileSwitch(
                    canPause: gameInProgress && isWon == false && isGameOver == false,
                    runtime: dependencies.sessionFlowRuntime
                )
            },
            onWinPlayAgain: {
                hideVictoryCelebration()
                showWinAlert = false
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
                GameSessionFlowCoordinator.startNewGame(
                    settings: settings,
                    runtime: dependencies.sessionFlowRuntime,
                    callbacks: sessionFlowCallbacks
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
                    runtime: dependencies.sessionFlowRuntime,
                    callbacks: sessionFlowCallbacks
                )
            },
            onLossAcknowledge: {
                gameplayStore.finalizeLoss()
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
            },
            onRestart: {
                GameSessionFlowCoordinator.startNewGame(
                    settings: settings,
                    runtime: dependencies.sessionFlowRuntime,
                    callbacks: sessionFlowCallbacks
                )
            }
        )
    }

    private var gameTurnFeedback: GameTurnFeedback {
        snapshot.gameTurnFeedback
    }

    private var sessionFlowCallbacks: GameSessionFlowCallbacks {
        GameSessionFlowCallbacks(
            hideVictoryCelebration: hideVictoryCelebration,
            startTimeLimits: startTimeLimits,
            resumeTimeLimitsAfterPause: resumeTimeLimitsAfterPause,
            focusGuessField: { focusGuessField() }
        )
    }

    private var profileSwitchCallbacks: GameProfileSwitchCallbacks {
        GameProfileSwitchCallbacks(
            setLastSelectedProfileId: { lastSelectedProfileId = $0 },
            saveSurrenderedGame: {
                saveGameToHistory(finalState: false, score: 0, endReason: .surrender)
            },
            hideVictoryCelebration: hideVictoryCelebration
        )
    }

    private var directProfileSwitchCallbacks: GameProfileSwitchCallbacks {
        GameProfileSwitchCallbacks(
            setLastSelectedProfileId: { lastSelectedProfileId = $0 },
            saveSurrenderedGame: {},
            hideVictoryCelebration: hideVictoryCelebration
        )
    }

    private var profileSelectionCallbacks: GameProfileSelectionCallbacks {
        GameProfileSelectionCallbacks(
            setShowNewProfileSheet: { showNewProfileSheet = $0 },
            setPendingProfileSwitchId: { pendingProfileSwitchId = $0 },
            setShowProfileSwitchDialog: { showProfileSwitchDialog = $0 },
            directSwitchCallbacks: directProfileSwitchCallbacks
        )
    }

    private var profileCreationCallbacks: GameProfileCreationCallbacks {
        GameProfileCreationCallbacks(
            clearName: { newProfileName = "" },
            dismissSheet: { showNewProfileSheet = false }
        )
    }

    private var playSoundEffect: (SoundPlayer.Effect, Bool, Double) -> Void {
        { effect, enabled, volume in
            dependencies.playSound(effect, enabled: enabled, volume: volume)
        }
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
                    profileStore: dependencies.profileStore,
                    lastSelectedProfileId: lastSelectedProfileId,
                    sessionFlowRuntime: dependencies.sessionFlowRuntime,
                    callbacks: profileSelectionCallbacks
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
            runtime: dependencies.sessionFlowRuntime,
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
            runtime: dependencies.turnRuntime,
            presentation: gameTurnPresentation(guessesAreEmpty: guesses.isEmpty),
            feedback: gameTurnFeedback,
            playSound: playSoundEffect
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
            runtime: dependencies.sessionFlowRuntime
        )
    }

    private func resumeAfterWindowCloseIfNeeded() {
        GameSessionFlowCoordinator.resumeAfterWindowCloseIfNeeded(
            runtime: dependencies.sessionFlowRuntime,
            isAnyTimerActive: isAnyTimerActive,
            callbacks: sessionFlowCallbacks
        )
    }

    private func endGameWithoutResult() {
        GameSessionFlowCoordinator.endGameWithoutResult(runtime: dependencies.sessionFlowRuntime)
    }

    private func resetGameSession() {
        GameSessionFlowCoordinator.resetGameSession(
            runtime: dependencies.sessionFlowRuntime,
            callbacks: sessionFlowCallbacks
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
                        callbacks: profileCreationCallbacks
                    )
                },
                onCancel: {
                    GameProfileSelectionCoordinator.cancelProfileCreation(
                        callbacks: profileCreationCallbacks
                    )
                }
            )
        }
    }
}
