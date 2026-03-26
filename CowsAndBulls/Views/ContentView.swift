//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit
internal import Combine

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
    private var currentRound: Int { gameplayStore.currentRound }
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
    private var showAnswer: String { gameplayStore.showAnswer }
    private var gameOverMessage: String { gameplayStore.gameOverMessage }
    private var perGuessRemainingSeconds: Int { gameSessionStore.perGuessRemainingSeconds }
    private var gameRemainingSeconds: Int { gameSessionStore.gameRemainingSeconds }
    private var guessDurations: [Int] { gameSessionStore.guessDurations }
    private var timeoutEndReason: HistoryItem.EndReason? { gameSessionStore.timeoutEndReason }
    private var isPaused: Bool { gameSessionStore.isPaused }
    private var maximumGuesses: Int { settings.maximumGuesses }
    private var showGuessCount: Bool { settings.showGuessCount }
    private var answerLength: Int { settings.answerLength }
    private var enableCelebration: Bool { settings.enableCelebration }
    private var enableHardMode: Bool { settings.enableHardMode }
    private var enableRepeats: Bool { settings.enableRepeats }
    private var enableSoundEffects: Bool { settings.enableSoundEffects }
    private var soundEffectsVolume: Double { settings.soundEffectsVolume }
    private var enablePerGuessTimeLimit: Bool { settings.enablePerGuessTimeLimit }
    private var enableGameTimeLimit: Bool { settings.enableGameTimeLimit }
    private var perGuessTimeLimitSeconds: Int { settings.perGuessTimeLimitSeconds }
    private var gameTimeLimitSeconds: Int { settings.gameTimeLimitSeconds }
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

    private var isWonBinding: Binding<Bool> {
        Binding(
            get: { gameplayStore.isWon },
            set: { gameplayStore.isWon = $0 }
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

        if result == .won {
            stopAllTimers()
            gameSessionStore.finishGame()
            SoundPlayer.shared.play(.win, enabled: enableSoundEffects, volume: soundEffectsVolume)
            if enableCelebration {
                playVictoryCelebration()
            } else {
                isWon = true
                showWinAlert = true
            }
        } else if result == .lost {
            stopAllTimers()
            gameSessionStore.finishGame()
            SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isGameOver = true
        } else {
            SoundPlayer.shared.play(.submit, enabled: enableSoundEffects, volume: soundEffectsVolume)
            restartPerGuessTimeLimit()
        }

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

    private func stopAllTimers() { timerController.stopAll() }

    private func startTimeLimits() {
        timerController.startTimers(
            perGuessActive: isPerGuessLimitActive,
            gameActive: isGameLimitActive,
            onPerGuessTick: { [gameSessionStore] in
                if gameSessionStore.tickPerGuessSecond() {
                    handleTimeLimitExpired(.perGuess)
                }
            },
            onGameTick: { [gameSessionStore] in
                if gameSessionStore.tickGameSecond() {
                    handleTimeLimitExpired(.game)
                }
            }
        )
    }

    private func resumeTimeLimitsAfterPause() {
        // Resume from remaining seconds instead of resetting limits.
        startTimeLimits()
    }

    private enum TimeLimitType { case perGuess, game }

    private func handleTimeLimitExpired(_ type: TimeLimitType) {
        stopAllTimers()
        gameSessionStore.markTimeout(type == .perGuess ? .timeoutPerGuess : .timeoutGame)
        if guesses.isEmpty {
            endGameWithoutResult()
            return
        }
        gameplayStore.presentGameOver(
            message: presentationRules.timeoutGameOverMessage(
                for: type == .perGuess ? .perGuess : .game,
                answer: answer
            )
        )
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
    }

    private func restartPerGuessTimeLimit() {
        gameSessionStore.restartPerGuessTimer(seconds: perGuessTimeLimitSeconds)
        timerController.restartPerGuessTimerIfNeeded(
            isActive: isPerGuessLimitActive,
            onPerGuessTick: { [gameSessionStore] in
                if gameSessionStore.tickPerGuessSecond() {
                    handleTimeLimitExpired(.perGuess)
                }
            }
        )
    }

    private func togglePause() {
        guard presentationRules.canTogglePause else { return }
        if isPaused {
            gameSessionStore.resume()
            resumeTimeLimitsAfterPause()
            focusGuessField()
        } else {
            stopAllTimers()
            gameSessionStore.pause()
        }
    }

    private func pauseForWindowClose() {
        guard presentationRules.canPauseForWindowClose else { return }
        stopAllTimers()
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
        stopAllTimers()
        gameSessionStore.markSurrender()
        gameplayStore.presentGameOver(message: presentationRules.surrenderGameOverMessage(answer: answer))
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
    }

    private func endGameWithoutResult() {
        stopAllTimers()
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
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                GameHeaderSection(context: gameHeaderContext, onTogglePause: togglePause)
                GameInputSection(context: gameInputContext, onSubmitGuess: submitGuess, focusBinding: $isGuessFieldFocused)
            }
            .frame(maxWidth: .infinity)
            .background(headerBackground)

            GuessesListSection(context: guessesListContext)

            GameFooterSection(
                context: gameFooterContext,
                onSurrender: { showSurrenderConfirmation = true },
                onRestart: startNewGame
            )
                .frame(maxWidth: .infinity)
        }
        .onAppear {
            if answer.isEmpty {
                resetGameSession()
            }
        }
        .onDisappear { hideVictoryCelebration() }
        .onChange(of: guess) {
            if gameInProgress == false, guess.isEmpty == false {
                let pendingGuess = guess
                startNewGame()
                guess = pendingGuess
            }
            updateLiveGuessValidation()
        }
        .confirmationDialog(localized("game.surrender.title"), isPresented: $showSurrenderConfirmation, titleVisibility: .visible) {
            Button(localized("game.surrender.action"), role: .destructive) {
                surrenderGame()
            }
            Button(localized("common.action.cancel"), role: .cancel) {}
        } message: {
            Text(localized("game.surrender.message"))
        }
        .confirmationDialog(localized("profile.switch.confirm.title"), isPresented: $showProfileSwitchDialog, titleVisibility: .visible) {
            Button(localized("profile.switch.confirm.surrender"), role: .destructive) {
                surrenderForProfileSwitch()
                if let pendingProfileSwitchId {
                    applyProfileSwitch(to: pendingProfileSwitchId)
                }
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchSurrender")
            Button(localized("profile.switch.confirm.pause")) {
                pauseGameForProfileSwitch()
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchPause")
            Button(localized("common.action.cancel"), role: .cancel) {
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchCancel")
        } message: {
            Text(localized("profile.switch.confirm.message"))
        }
        .alert(localized("game.alert.win.title"), isPresented: showWinAlertBinding) {
            Button(localized("common.action.play_again")) {
                hideVictoryCelebration()
                showWinAlert = false
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
                startNewGame()
            }
            Button(localized("common.action.ok")) {
                hideVictoryCelebration()
                showWinAlert = false
                gameplayStore.finalizeWin()
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
            }
        } message: { Text(localized("alert.win.message", guesses.count, scoreValue)) }
        .alert(localized("game.alert.lose.title"), isPresented: isGameOverBinding) {
            Button(localized("common.action.play_again")) {
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
                startNewGame()
            }
            Button(localized("common.action.ok")) {
                gameplayStore.finalizeLoss()
                saveGameToHistory(finalState: false, score: 0, endReason: presentationRules.lossEndReason(timeoutEndReason: timeoutEndReason))
            }
        } message: { Text(presentationRules.lossAlertMessage(answer: answer, gameOverMessage: gameOverMessage)) }
        .tabItem { Label(localized("tab.game"), systemImage: "gamecontroller") }
    }

    private var headerBackground: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .opacity(0.05)
            .allowsHitTesting(false)
            .clipped()
    }

}

private struct GameHeaderSection: View {
    let context: GameHeaderContext
    let onTogglePause: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ProfilePickerRow(
                profiles: context.profiles,
                selection: context.profileSelection,
                canChangeProfile: context.canChangeProfile,
                helpText: context.profilePickerHelpText
            )

            Text(context.gameModeMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                Text(localized("game.header.avg_steps", context.averageSteps))
                    .padding(.trailing, 10)
                Text(localized("game.header.best_streak", context.bestWinStreak))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            HStack(spacing: 2) {
                Text(localized("settings.theme.label"))
                Image(context.selectedBullAssetName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .animalIconStyle()
                Image(context.selectedCowAssetName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .animalIconStyle()
            }
            .padding(.bottom, 4)

            if context.isAnyTimerActive {
                TimerStatusBar(
                    isPerGuessLimitActive: context.isPerGuessLimitActive,
                    isGameLimitActive: context.isGameLimitActive,
                    perGuessRemainingSeconds: context.perGuessRemainingSeconds,
                    gameRemainingSeconds: context.gameRemainingSeconds,
                    isPaused: context.isPaused,
                    onTogglePause: onTogglePause
                )
            }
        }
        .padding(.top, 12)
    }
}

private struct ProfilePickerRow: View {
    let profiles: [PlayerProfile]
    let selection: Binding<String>
    let canChangeProfile: Bool
    let helpText: String

    var body: some View {
        HStack(spacing: 8) {
            Text(localized("profile.label"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker(localized("profile.label"), selection: selection) {
                ForEach(profiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
                Divider()
                Text(localized("profile.new.picker")).tag(ProfileStore.newProfileSelectionId)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(canChangeProfile == false)
            .help(helpText)
            .accessibilityIdentifier("profilePicker")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profilePickerRow")
    }
}

private struct TimerStatusBar: View {
    let isPerGuessLimitActive: Bool
    let isGameLimitActive: Bool
    let perGuessRemainingSeconds: Int
    let gameRemainingSeconds: Int
    let isPaused: Bool
    let onTogglePause: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isPerGuessLimitActive {
                Label(GameLogic.formatTime(perGuessRemainingSeconds), systemImage: "timer")
            }
            if isGameLimitActive {
                Label(GameLogic.formatTime(gameRemainingSeconds), systemImage: "hourglass")
            }
            Button(isPaused ? localized("game.timer.resume") : localized("game.timer.pause")) {
                onTogglePause()
            }
        }
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(.orange)
        .accessibilityIdentifier("timerStatusBar")
    }
}

private struct GameInputSection: View {
    let context: GameInputContext
    let onSubmitGuess: () -> Void
    let focusBinding: FocusState<Bool>.Binding

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                TextField(localized("game.input.placeholder"), text: context.guessBinding)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .focused(focusBinding)
                    .onSubmit(onSubmitGuess)
                    .textFieldStyle(.roundedBorder)
                    .disabled(context.isPaused)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("guessInputField")

                Button(localized("game.input.submit"), action: onSubmitGuess)
                    .padding(4)
                    .disabled(context.isDisabledSubmitButton || context.isPaused)
                    .accessibilityIdentifier("submitGuessButton")
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 360)

            Text(context.guessInputErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(minHeight: 14, alignment: .top)
                .accessibilityHidden(context.guessInputErrorMessage.isEmpty)
                .accessibilityValue(context.guessInputErrorMessage)
                .accessibilityIdentifier("guessInputError")
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

private struct GuessesListSection: View {
    let context: GuessesListContext

    private var guessesAccessibilityValue: String {
        context.guesses.joined(separator: "|")
    }

    var body: some View {
        List(0..<context.guesses.count, id: \.self) { index in
            let attempt = context.guesses[index]
            let duration = index < context.guessDurations.count ? context.guessDurations[index] : 0
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedGuessDisplay(attempt))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .kerning(1)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: guessDisplayWidth, alignment: .leading)
                    Text(GameLogic.formatDuration(TimeInterval(duration)))
                        .font(.system(size: 9))
                        .listStyle(.sidebar)
                }
                Spacer()
                GuessResultIconsView(
                    guess: attempt,
                    answer: context.answer,
                    bullAssetName: context.selectedBullAssetName,
                    cowAssetName: context.selectedCowAssetName
                )
            }
        }
        .listStyle(.sidebar)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("guessesList")
        .accessibilityValue(guessesAccessibilityValue)
    }

    private var guessDisplayWidth: CGFloat { 72 }

    private func formattedGuessDisplay(_ guess: String) -> String {
        guard guess.count > 4 else { return guess }
        let splitIndex = guess.index(guess.startIndex, offsetBy: 4)
        return String(guess[..<splitIndex]) + "\n" + String(guess[splitIndex...])
    }
}

private struct GuessResultIconsView: View {
    let guess: String
    let answer: String
    let bullAssetName: String
    let cowAssetName: String

    var body: some View {
        let counts = GameLogic.bullCowCounts(guess: guess, answer: answer)
        let iconNames = Array(repeating: bullAssetName, count: counts.bulls)
            + Array(repeating: cowAssetName, count: counts.cows)

        if iconNames.isEmpty {
            Text("0").foregroundStyle(.secondary)
        } else if guess.count > 4 {
            VStack(alignment: .trailing, spacing: 4) {
                iconRow(iconNames.prefix(4))
                iconRow(iconNames.dropFirst(4))
            }
        } else {
            iconRow(iconNames[...])
        }
    }

    private func iconRow(_ icons: ArraySlice<String>) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(icons.enumerated()), id: \.offset) { _, name in
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .animalIconStyle()
            }
        }
    }
}

private struct GameFooterSection: View {
    let context: GameFooterContext
    let onSurrender: () -> Void
    let onRestart: () -> Void

    var body: some View {
        VStack {
            if context.showGuessCount {
                Text(localized("Guesses: %lld/%lld", context.guessesCount, context.maximumGuesses))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }

            Text(String(context.guessesCount))
                .font(.caption2)
                .accessibilityIdentifier("gameGuessCountState")
                .accessibilityValue(String(context.guessesCount))

            HStack(spacing: 12) {
                Button(localized("game.action.surrender")) {
                    onSurrender()
                }
                .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.0))
                .disabled(context.canSurrender == false)

                Button(localized("game.action.restart"), action: onRestart)
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 20)
        }
    }
}

private struct NewProfileSheet: View {
    @Binding var name: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized("profile.new.title"))
                .font(.headline)

            TextField(localized("profile.new.placeholder"), text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
                .accessibilityIdentifier("newProfileNameField")

            HStack {
                Spacer()
                Button(localized("common.action.cancel"), role: .cancel, action: onCancel)
                    .accessibilityIdentifier("newProfileCancel")
                Button(localized("profile.new.action")) {
                    onCreate(name)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("newProfileCreate")
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            isNameFocused = true
        }
    }
}

private struct GameHeaderContext {
    let profiles: [PlayerProfile]
    let profileSelection: Binding<String>
    let canChangeProfile: Bool
    let profilePickerHelpText: String
    let gameModeMessage: String
    let averageSteps: Double
    let bestWinStreak: Int
    let selectedBullAssetName: String
    let selectedCowAssetName: String
    let isAnyTimerActive: Bool
    let isPerGuessLimitActive: Bool
    let isGameLimitActive: Bool
    let perGuessRemainingSeconds: Int
    let gameRemainingSeconds: Int
    let isPaused: Bool
}

private struct GameInputContext {
    let guessBinding: Binding<String>
    let isPaused: Bool
    let isDisabledSubmitButton: Bool
    let guessInputErrorMessage: String
}

private struct GuessesListContext {
    let guesses: [String]
    let guessDurations: [Int]
    let answer: String
    let selectedBullAssetName: String
    let selectedCowAssetName: String
}

private struct GameFooterContext {
    let showGuessCount: Bool
    let guessesCount: Int
    let maximumGuesses: Int
    let canSurrender: Bool
}
