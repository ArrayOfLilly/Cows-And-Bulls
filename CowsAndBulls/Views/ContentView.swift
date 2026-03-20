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
    @State private var perGuessTimerTask: Task<Void, Never>?
    @State private var gameTimerTask: Task<Void, Never>?
    
    
    @State private var showSurrenderConfirmation = false
    @State private var showNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var lastSelectedProfileId = ""
    @State private var pendingProfileSwitchId: String?
    @State private var showProfileSwitchDialog = false
    @State private var showWinAlert = false
    @State private var showVictoryCelebration = false
    @State private var victoryAnimationProgress: CGFloat = 0
    @State private var victoryFrameIndex = 0
    @State private var winAlertTask: Task<Void, Never>?
    @State private var victoryFrameTask: Task<Void, Never>?
    
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

    private func scoreForTimers(
        enablePerGuess: Bool,
        perGuessSeconds: Int,
        enableGame: Bool,
        gameSeconds: Int
    ) -> Int {
        let perMoveLimit = (enablePerGuess && perGuessSeconds > 0) ? TimeInterval(perGuessSeconds) : 0
        let totalLimit = (enableGame && gameSeconds > 0) ? TimeInterval(gameSeconds) : 0
        return GameLogic.score(
            codeLength: answerLength,
            allowRepeats: enableRepeats,
            hardMode: enableHardMode,
            hidesRemainingGuesses: showGuessCount == false,
            maxGuesses: maximumGuesses,
            usedGuesses: guesses.count,
            perMoveTimeLimit: perMoveLimit,
            totalTimeLimit: totalLimit
        )
    }

    private var scoreValue: Int {
        let startedSnapshot = gameSessionStore.startedSettingsSnapshot ?? settings.gameplaySettingsSnapshot
        // Fairness rule: if timer settings were changed mid-game, use the lower score
        // between "started configuration" and "current configuration".
        let currentScore = scoreForTimers(
            enablePerGuess: enablePerGuessTimeLimit,
            perGuessSeconds: perGuessTimeLimitSeconds,
            enableGame: enableGameTimeLimit,
            gameSeconds: gameTimeLimitSeconds
        )
        let startedScore = scoreForTimers(
            enablePerGuess: startedSnapshot.enablePerGuessTimeLimit,
            perGuessSeconds: startedSnapshot.perGuessTimeLimitSeconds,
            enableGame: startedSnapshot.enableGameTimeLimit,
            gameSeconds: startedSnapshot.gameTimeLimitSeconds
        )
        return min(currentScore, startedScore)
    }

    private var isPerGuessLimitActive: Bool { enablePerGuessTimeLimit && perGuessTimeLimitSeconds > 0 }
    private var isGameLimitActive: Bool { enableGameTimeLimit && gameTimeLimitSeconds > 0 }
    private var isAnyTimerActive: Bool { isPerGuessLimitActive || isGameLimitActive }
    private var canChangeProfile: Bool { gameInProgress == false }

    private var profileSelection: Binding<String> {
        Binding(
            get: { profileStore.selectedProfileId },
            set: { newValue in
                if newValue == ProfileStore.newProfileSelectionId {
                    showNewProfileSheet = true
                    profileStore.selectProfile(id: lastSelectedProfileId)
                    return
                }
                if canChangeProfile == false {
                    pendingProfileSwitchId = newValue
                    showProfileSwitchDialog = true
                    profileStore.selectProfile(id: lastSelectedProfileId)
                    return
                }
                applyProfileSwitch(to: newValue)
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
    
    private var gameModeMessage: String {
        var message = localized("game.mode.title") + " "
        if enableHardMode {
            message += String(localized: "game.mode.hard") + " "
        } else {
            message += String(localized: "game.mode.normal") + " "
        }
        message += String(localized: "game.mode.format") + " " + String(self.answerLength) + " "
        if enableRepeats {
            message += String(localized: "game.mode.repeats")
        } else {
            message += String(localized: "game.mode.unique")
        }
            return message
    }

    // MARK: - Lifecycle
    
    private func startNewGame() {
        hideVictoryCelebration()
        stopAllTimers()
        gameSessionStore.resetSession()
        gameplayStore.startNewGame(settings: settings)
        guard gameplayStore.answer.isEmpty == false else { return }
        gameSessionStore.beginGame(with: settings)
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
            playVictoryCelebration()
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

    private func stopAllTimers() {
        perGuessTimerTask?.cancel()
        perGuessTimerTask = nil
        gameTimerTask?.cancel()
        gameTimerTask = nil
    }

    private func startTimeLimits() {
        if isPerGuessLimitActive {
            startPerGuessTimer()
        }
        if isGameLimitActive {
            startGameTimer()
        }
    }

    private func resumeTimeLimitsAfterPause() {
        // Resume from remaining seconds instead of resetting limits.
        if isPerGuessLimitActive {
            startPerGuessTimer()
        }
        if isGameLimitActive {
            startGameTimer()
        }
    }

    private func startPerGuessTimer() {
        perGuessTimerTask?.cancel()
        perGuessTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                await MainActor.run {
                    if gameSessionStore.tickPerGuessSecond() {
                        handleTimeLimitExpired(.perGuess)
                    }
                }
            }
        }
    }

    private func startGameTimer() {
        gameTimerTask?.cancel()
        gameTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                await MainActor.run {
                    if gameSessionStore.tickGameSecond() {
                        handleTimeLimitExpired(.game)
                    }
                }
            }
        }
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
            message: type == .perGuess
                ? localized("alert.per_guess_timeout.message", answer)
                : localized("alert.game_timeout.message", answer)
        )
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
    }

    private func restartPerGuessTimeLimit() {
        gameSessionStore.restartPerGuessTimer(seconds: perGuessTimeLimitSeconds)
    }

    private func togglePause() {
        guard isAnyTimerActive, isWon == false, isGameOver == false else { return }
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
        guard isWon == false, isGameOver == false else { return }
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
        gameplayStore.presentGameOver(message: localized("alert.surrender.message", answer))
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
    }

    private func endGameWithoutResult() {
        stopAllTimers()
        gameSessionStore.resetSession()
        gameplayStore.reset()
    }

    private func profilePickerHelpText() -> String {
        if gameInProgress && guesses.isEmpty == false {
            return localized("profile.switch.disabled.in_progress")
        }
        if gameInProgress {
            return localized("profile.switch.disabled.in_progress")
        }
        return ""
    }

    private func applyProfileSwitch(to profileId: String) {
        profileStore.selectProfile(id: profileId)
        lastSelectedProfileId = profileId
        resetGameSession()
    }

    private func resetGameSession() {
        hideVictoryCelebration()
        stopAllTimers()
        gameSessionStore.resetSession()
        gameplayStore.reset()
    }

    private func surrenderForProfileSwitch() {
        guard guesses.isEmpty == false else {
            resetGameSession()
            return
        }
        stopAllTimers()
        gameSessionStore.markSurrender()
        saveGameToHistory(finalState: false, score: 0, endReason: .surrender)
        resetGameSession()
    }

    private func pauseGameForProfileSwitch() {
        guard gameInProgress, isWon == false, isGameOver == false else { return }
        stopAllTimers()
        gameSessionStore.pause()
    }

    private func focusGuessField(selectAll: Bool = false) {
        DispatchQueue.main.async {
            isGuessFieldFocused = true
            if selectAll { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
        }
    }

    private func playVictoryCelebration() {
        let duration = VictoryCowOverlay.animationDuration
        winAlertTask?.cancel()
        victoryFrameTask?.cancel()
        showWinAlert = false
        victoryAnimationProgress = 0
        victoryFrameIndex = 0
        showVictoryCelebration = true
        DispatchQueue.main.async {
            withAnimation(.linear(duration: duration)) {
                victoryAnimationProgress = 1
            }
        }
        victoryFrameTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(0.10))
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    victoryFrameIndex = (victoryFrameIndex + 1) % VictoryCowOverlay.assetCount
                }
            }
        }
        winAlertTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                showVictoryCelebration = false
                victoryAnimationProgress = 0
                victoryFrameIndex = 0
                isWon = true
                showWinAlert = true
            }
        }
    }

    private func hideVictoryCelebration() {
        winAlertTask?.cancel()
        winAlertTask = nil
        victoryFrameTask?.cancel()
        victoryFrameTask = nil
        showVictoryCelebration = false
        victoryAnimationProgress = 0
        victoryFrameIndex = 0
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
                    gameInProgress && guesses.isEmpty == false && isWon == false && isGameOver == false
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
                GameHeaderSection(
                    profiles: profileStore.profiles,
                    profileSelection: profileSelection,
                    canChangeProfile: canChangeProfile,
                    profilePickerHelpText: profilePickerHelpText(),
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
                    isPaused: isPaused,
                    onTogglePause: togglePause
                )
                GameInputSection(
                    guessBinding: guessBinding,
                    isPaused: isPaused,
                    isDisabledSubmitButton: isDisabledSubmitButton,
                    guessInputErrorMessage: guessInputErrorMessage,
                    onSubmitGuess: submitGuess,
                    focusBinding: $isGuessFieldFocused
                )
            }
            .frame(maxWidth: .infinity)
            .background(headerBackground)

            GuessesListSection(
                guesses: guesses,
                guessDurations: guessDurations,
                answer: answer,
                selectedBullAssetName: selectedBullAssetName,
                selectedCowAssetName: selectedCowAssetName
            )

            GameFooterSection(
                showGuessCount: showGuessCount,
                guessesCount: guesses.count,
                maximumGuesses: maximumGuesses,
                canSurrender: gameInProgress && !guesses.isEmpty && !isWon && !isGameOver,
                onSurrender: {
                    showSurrenderConfirmation = true
                },
                onRestart: startNewGame
            )
                .frame(maxWidth: .infinity)
        }
        .overlay {
            if showVictoryCelebration {
                VictoryCowOverlay(
                    progress: victoryAnimationProgress,
                    frameIndex: victoryFrameIndex
                )
                    .zIndex(10)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.identity)
            }
        }
        .onAppear {
            if answer.isEmpty {
                resetGameSession()
            }
        }
        .onDisappear {
            hideVictoryCelebration()
        }
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
                saveGameToHistory(finalState: false, score: 0, endReason: timeoutEndReason ?? .completed)
                startNewGame()
            }
            Button(localized("common.action.ok")) {
                gameplayStore.finalizeLoss()
                saveGameToHistory(finalState: false, score: 0, endReason: timeoutEndReason ?? .completed)
            }
        } message: { Text(gameOverMessage.isEmpty ? localized("alert.lose.message", answer) : gameOverMessage) }
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
    let onTogglePause: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ProfilePickerRow(
                profiles: profiles,
                selection: profileSelection,
                canChangeProfile: canChangeProfile,
                helpText: profilePickerHelpText
            )

            Text(gameModeMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                Text(localized("game.header.avg_steps", averageSteps))
                    .padding(.trailing, 10)
                Text(localized("game.header.best_streak", bestWinStreak))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            HStack(spacing: 12) {
                Text(localized("settings.theme.label"))
                Image(selectedBullAssetName)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .animalIconStyle(cornerRadius: 6)
                Image(selectedCowAssetName)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .animalIconStyle(cornerRadius: 6)
            }
            .padding(.bottom, 4)

            if isAnyTimerActive {
                TimerStatusBar(
                    isPerGuessLimitActive: isPerGuessLimitActive,
                    isGameLimitActive: isGameLimitActive,
                    perGuessRemainingSeconds: perGuessRemainingSeconds,
                    gameRemainingSeconds: gameRemainingSeconds,
                    isPaused: isPaused,
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
    let guessBinding: Binding<String>
    let isPaused: Bool
    let isDisabledSubmitButton: Bool
    let guessInputErrorMessage: String
    let onSubmitGuess: () -> Void
    let focusBinding: FocusState<Bool>.Binding

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                TextField(localized("game.input.placeholder"), text: guessBinding)
                    .focused(focusBinding)
                    .onSubmit(onSubmitGuess)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isPaused)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("guessInputField")

                Button(localized("game.input.submit"), action: onSubmitGuess)
                    .disabled(isDisabledSubmitButton || isPaused)
                    .accessibilityIdentifier("submitGuessButton")
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 360)

            Text(guessInputErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(minHeight: 14, alignment: .top)
                .accessibilityHidden(guessInputErrorMessage.isEmpty)
                .accessibilityValue(guessInputErrorMessage)
                .accessibilityIdentifier("guessInputError")
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

private struct GuessesListSection: View {
    let guesses: [String]
    let guessDurations: [Int]
    let answer: String
    let selectedBullAssetName: String
    let selectedCowAssetName: String

    var body: some View {
        List(0..<guesses.count, id: \.self) { index in
            let attempt = guesses[index]
            let duration = index < guessDurations.count ? guessDurations[index] : 0
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
                    answer: answer,
                    bullAssetName: selectedBullAssetName,
                    cowAssetName: selectedCowAssetName
                )
            }
        }
        .listStyle(.sidebar)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("guessesList")
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
        HStack(spacing: 6) {
            ForEach(Array(icons.enumerated()), id: \.offset) { _, name in
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .animalIconStyle(cornerRadius: 6)
            }
        }
    }
}

private struct VictoryCowOverlay: View {
    static let animationDuration: TimeInterval = 2.8
    static let assetCount = 4

    let progress: CGFloat
    let frameIndex: Int
    private let assetNames = [
        "Walking Cow frame 1",
        "Walking Cow frame 2",
        "Walking Cow frame 3",
        "Walking Cow frame 4",
    ]

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let cowSize = min(max(proxy.size.width * 0.18, 110), 180)
            let startX = -cowSize * 0.7
            let endX = proxy.size.width + cowSize * 0.4
            let x = startX + (endX - startX) * clampedProgress
            let startY = proxy.size.height * 0.88
            let endY = proxy.size.height * 0.18
            let diagonalY = startY + (endY - startY) * clampedProgress
            let arcLift = sin(clampedProgress * .pi) * proxy.size.height * 0.10
            let bob = sin(clampedProgress * .pi * 8) * 5
            let y = diagonalY - arcLift + bob

            Image(assetNames[frameIndex % assetNames.count])
                .resizable()
                .scaledToFit()
                .frame(width: cowSize, height: cowSize)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
                .position(x: x, y: y)
                .zIndex(10)
        }
    }
}

private struct GameFooterSection: View {
    let showGuessCount: Bool
    let guessesCount: Int
    let maximumGuesses: Int
    let canSurrender: Bool
    let onSurrender: () -> Void
    let onRestart: () -> Void

    var body: some View {
        VStack {
            if showGuessCount {
                Text(localized("Guesses: %lld/%lld", guessesCount, maximumGuesses))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }

            HStack(spacing: 12) {
                Button(localized("game.action.surrender")) {
                    onSurrender()
                }
                .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.0))
                .disabled(canSurrender == false)

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
