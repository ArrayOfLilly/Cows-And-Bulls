//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit

struct ContentView: View {
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

    // MARK: - Computed Properties

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
    private var enablePerGuessTimeLimit: Bool { settings.enablePerGuessTimeLimit }
    private var enableGameTimeLimit: Bool { settings.enableGameTimeLimit }
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

    private var gameTurnRuntime: GameTurnRuntime {
        GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
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
                switch presentationRules.decisionForProfileSelection(
                    newValue,
                    newProfileSelectionId: ProfileStore.newProfileSelectionId
                ) {
                case .showNewProfileSheet:
                    showNewProfileSheet = true
                    profileStore.selectProfile(id: lastSelectedProfileId)
                case let .confirmInProgressSwitch(profileId):
                    pendingProfileSwitchId = profileId
                    showProfileSwitchDialog = true
                    profileStore.selectProfile(id: lastSelectedProfileId)
                case let .switchDirectly(profileId):
                    applyProfileSwitch(to: profileId)
                }
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

    // MARK: - Lifecycle
    
    private func startNewGame() {
        GameCoordinator.startNewGame(
            settings: settings,
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            timerController: timerController,
            hideVictoryCelebration: hideVictoryCelebration
        )
        guard gameplayStore.answer.isEmpty == false else { return }
        startTimeLimits()
        focusGuessField()
    }

    private func submitGuess() {
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
    }

    private func updateLiveGuessValidation() {
        gameplayStore.updateLiveGuessValidation(settings: settings)
    }

    private func saveGameToHistory(finalState: Bool, score: Int, endReason: HistoryItem.EndReason = .completed) {
        guard let item = gameSessionStore.makeHistoryItem(
            finalState: finalState,
            answer: answer,
            guesses: guesses,
            score: score,
            currentSettings: settings,
            endReason: endReason
        ) else {
            return
        }
        historyStore.add(item)
    }

    // MARK: - Timers

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
        // Resume from remaining seconds instead of resetting limits.
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

    private func togglePause() {
        guard presentationRules.canTogglePause else { return }
        if isPaused {
            gameSessionStore.resume()
            resumeTimeLimitsAfterPause()
            focusGuessField()
        } else {
            timerController.stopAll()
            gameSessionStore.pause()
        }
    }

    private func pauseForWindowClose() {
        guard presentationRules.canPauseForWindowClose else { return }
        timerController.stopAll()
        gameSessionStore.pause(dueToWindowClose: true)
    }

    private func resumeAfterWindowCloseIfNeeded() {
        guard gameSessionStore.resumeAfterWindowCloseIfNeeded() else { return }
        if isAnyTimerActive {
            resumeTimeLimitsAfterPause()
        }
        focusGuessField()
    }

    private func surrenderGame() {
        guard gameInProgress, guesses.isEmpty == false, isWon == false, isGameOver == false else { return }
        GameTurnCoordinator.surrenderGame(
            runtime: gameTurnRuntime,
            presentation: gameTurnPresentation(guessesAreEmpty: guesses.isEmpty),
            feedback: gameTurnFeedback,
            playSound: { effect, enabled, volume in
                SoundPlayer.shared.play(effect, enabled: enabled, volume: volume)
            }
        )
    }

    private func endGameWithoutResult() {
        timerController.stopAll()
        gameSessionStore.resetSession()
        gameplayStore.reset()
    }

    private func applyProfileSwitch(to profileId: String) {
        profileStore.selectProfile(id: profileId)
        lastSelectedProfileId = profileId
        resetGameSession()
    }

    private func resetGameSession() {
        GameCoordinator.resetGameSession(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            timerController: timerController,
            hideVictoryCelebration: hideVictoryCelebration
        )
    }

    private func surrenderForProfileSwitch() {
        GameCoordinator.surrenderForProfileSwitch(
            hasGuesses: guesses.isEmpty == false,
            gameSessionStore: gameSessionStore,
            timerController: timerController,
            saveSurrenderedGame: {
                saveGameToHistory(finalState: false, score: 0, endReason: .surrender)
            },
            resetGameSession: resetGameSession
        )
    }

    private func pauseGameForProfileSwitch() {
        GameCoordinator.pauseGameForProfileSwitch(
            canPause: gameInProgress && isWon == false && isGameOver == false,
            gameSessionStore: gameSessionStore,
            timerController: timerController
        )
    }

    private func focusGuessField(selectAll: Bool = false) {
        DispatchQueue.main.async {
            isGuessFieldFocused = true
            if selectAll { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
        }
    }

    private func playVictoryCelebration() {
        showWinAlert = false
        VictoryCelebrationWindowController.shared.present(from: NSApp.keyWindow ?? NSApp.mainWindow) { [self] in
            isWon = true
            showWinAlert = true
        }
    }

    private func hideVictoryCelebration() {
        VictoryCelebrationWindowController.shared.dismiss()
    }

    // MARK: - UI

    var body: some View {
        TabView {
            gameTab
            HistoryView()
            StatisticView()
        }
        .frame(minWidth: 450, idealWidth: 450)
        .frame(minHeight: 600, idealHeight: 600)
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
                onGiveUp: {
                    surrenderGame()
                },
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
                    profileStore.createProfile(named: name)
                    newProfileName = ""
                    showNewProfileSheet = false
                },
                onCancel: {
                    newProfileName = ""
                    showNewProfileSheet = false
                }
            )
        }
    }

    private var gameTab: some View {
        GameTabView(
            context: gameTabContext,
            showSurrenderConfirmation: $showSurrenderConfirmation,
            pendingProfileSwitchId: $pendingProfileSwitchId,
            showProfileSwitchDialog: $showProfileSwitchDialog,
            showWinAlert: showWinAlertBinding,
            isGameOver: isGameOverBinding,
            focusBinding: $isGuessFieldFocused,
            onAppear: {
                if answer.isEmpty {
                    resetGameSession()
                }
            },
            onDisappear: hideVictoryCelebration,
            onGuessChange: {
                if gameInProgress == false, guess.isEmpty == false {
                    let pendingGuess = guess
                    startNewGame()
                    guess = pendingGuess
                }
                updateLiveGuessValidation()
            },
            onTogglePause: togglePause,
            onSubmitGuess: submitGuess,
            onSurrender: surrenderGame,
            onConfirmProfileSwitchSurrender: {
                surrenderForProfileSwitch()
                if let pendingProfileSwitchId {
                    applyProfileSwitch(to: pendingProfileSwitchId)
                }
            },
            onConfirmProfileSwitchPause: pauseGameForProfileSwitch,
            onWinPlayAgain: {
                hideVictoryCelebration()
                showWinAlert = false
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
                startNewGame()
            },
            onWinAcknowledge: {
                hideVictoryCelebration()
                showWinAlert = false
                gameplayStore.finalizeWin()
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
            },
            onLossPlayAgain: {
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
                startNewGame()
            },
            onLossAcknowledge: {
                gameplayStore.finalizeLoss()
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
            },
            onRestart: startNewGame
        )
    }

}
