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
    @AppStorage("maximumGuesses") private var maximumGuesses = 10
    @AppStorage("showGuessCount") private var showGuessCount = false
    @AppStorage("answerLength") private var answerLength = 4
    @AppStorage("enableHardMode") private var enableHardMode = false
    @AppStorage("enableRepeats") private var enableRepeats = false
    @AppStorage("enableSoundEffects") private var enableSoundEffects = true
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume = 0.8
    @AppStorage("enablePerGuessTimeLimit") private var enablePerGuessTimeLimit = false
    @AppStorage("enableGameTimeLimit") private var enableGameTimeLimit = false
    @AppStorage("perGuessTimeLimitSeconds") private var perGuessTimeLimitSeconds = 30
    @AppStorage("gameTimeLimitSeconds") private var gameTimeLimitSeconds = 300
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"
    @AppStorage("gameInProgress") private var gameInProgress = false

    @EnvironmentObject private var historyStore: HistoryStore

    @State private var answer = ""
    @State private var guesses: [String] = []
    @State private var guess = ""
    @State private var currentRound = 0
    @State private var isWon = false
    @State private var isGameOver = false
    @State private var isDisabledSubmitButton = false
    @State private var guessInputErrorMessage = ""
    @State private var showAnswer = ""
    @State private var gameOverMessage = ""
    @State private var perGuessRemainingSeconds = 0
    @State private var gameRemainingSeconds = 0
    @State private var perGuessTimerTask: Task<Void, Never>?
    @State private var gameTimerTask: Task<Void, Never>?
    
    
    // Timing states
    @State private var gameStartTime: Date?
    @State private var lastGuessTime: Date?
    @State private var guessDurations: [Int] = []
    @State private var gameEndTime: Date?
    @State private var timeoutEndReason: HistoryItem.EndReason?
    @State private var showSurrenderConfirmation = false
    @State private var startedEnablePerGuessTimeLimit = false
    @State private var startedEnableGameTimeLimit = false
    @State private var startedPerGuessTimeLimitSeconds = 30
    @State private var startedGameTimeLimitSeconds = 300
    @State private var isPaused = false
    @State private var pauseStartedAt: Date?
    
    @FocusState private var isGuessFieldFocused: Bool

    // MARK: - Computed Properties

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
        // Fairness rule: if timer settings were changed mid-game, use the lower score
        // between "started configuration" and "current configuration".
        let currentScore = scoreForTimers(
            enablePerGuess: enablePerGuessTimeLimit,
            perGuessSeconds: perGuessTimeLimitSeconds,
            enableGame: enableGameTimeLimit,
            gameSeconds: gameTimeLimitSeconds
        )
        let startedScore = scoreForTimers(
            enablePerGuess: startedEnablePerGuessTimeLimit,
            perGuessSeconds: startedPerGuessTimeLimitSeconds,
            enableGame: startedEnableGameTimeLimit,
            gameSeconds: startedGameTimeLimitSeconds
        )
        return min(currentScore, startedScore)
    }

    private var isPerGuessLimitActive: Bool { enablePerGuessTimeLimit && perGuessTimeLimitSeconds > 0 }
    private var isGameLimitActive: Bool { enableGameTimeLimit && gameTimeLimitSeconds > 0 }
    private var isAnyTimerActive: Bool { isPerGuessLimitActive || isGameLimitActive }
    
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
    
    private func resetTimerDisplayToZero() {
           perGuessRemainingSeconds = 0
           gameRemainingSeconds     = 0
       }

    private func startNewGame() {
        stopAllTimers()
        perGuessRemainingSeconds = perGuessTimeLimitSeconds
        gameRemainingSeconds    = gameTimeLimitSeconds
        resetTimerDisplayToZero()
        
        guard answerLength >= 3 && answerLength <= 8 else {
            guessInputErrorMessage = String(localized: "validation.answer_length_range")
            return
        }

        showAnswer = ""
        guess = ""
        guesses.removeAll()
        guessDurations.removeAll()
        answer = GameLogic.generateAnswer(length: answerLength, allowRepeats: enableRepeats)
        currentRound = 0
        isDisabledSubmitButton = false
        gameOverMessage = ""
        gameInProgress = true
        
        // Mark starting timestamps
        let now = Date()
        gameStartTime = now
        lastGuessTime = now
        gameEndTime = nil
        timeoutEndReason = nil
        startedEnablePerGuessTimeLimit = enablePerGuessTimeLimit
        startedEnableGameTimeLimit = enableGameTimeLimit
        startedPerGuessTimeLimitSeconds = perGuessTimeLimitSeconds
        startedGameTimeLimitSeconds = gameTimeLimitSeconds
        isPaused = false
        pauseStartedAt = nil
        
        startTimeLimits()
        focusGuessField()
    }

    private func submitGuess() {
        let errors = validationErrors(for: guess, includeLengthError: true)
        if errors.isEmpty == false {
            guessInputErrorMessage = errors.joined(separator: "\n")
            focusGuessField(selectAll: true)
            return
        }

        // Measure time taken for this guess
        let now = Date()
        let elapsed = now.timeIntervalSince(lastGuessTime ?? now)
        guessDurations.insert(Int(elapsed.rounded()), at: 0) // Aligning with guesses order (newest first)
        lastGuessTime = now

        let counts = GameLogic.bullCowCounts(guess: guess, answer: answer)
        withAnimation {
            guesses.insert(guess, at: 0)
        }
        currentRound += 1

        if counts.bulls == answerLength {
            stopAllTimers()
            gameEndTime = Date()
            gameInProgress = false
            isPaused = false
            pauseStartedAt = nil
            SoundPlayer.shared.play(.win, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isWon = true
        } else if currentRound == maximumGuesses {
            stopAllTimers()
            gameEndTime = Date()
            gameInProgress = false
            isPaused = false
            pauseStartedAt = nil
            gameOverMessage = localized("alert.lose.message", answer)
            SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isGameOver = true
        } else {
            SoundPlayer.shared.play(.submit, enabled: enableSoundEffects, volume: soundEffectsVolume)
            restartPerGuessTimeLimit()
        }

        guess = ""
        focusGuessField()
    }

    private func updateLiveGuessValidation() {
        guard guess.isEmpty == false else {
            guessInputErrorMessage = ""
            return
        }
        let errors = validationErrors(for: guess, includeLengthError: false)
        // Length validation is intentionally omitted while typing.
        guessInputErrorMessage = errors.joined(separator: "\n")
    }

    private func validationErrors(for guess: String, includeLengthError: Bool) -> [String] {
        var messages: [String] = []

        if includeLengthError && guess.count != answerLength {
            messages.append(localized("validation.answer_length", answerLength))
        }

        let badCharacters = CharacterSet(charactersIn: "0123456789").inverted
        if guess.rangeOfCharacter(from: badCharacters) != nil {
            messages.append(String(localized: "validation.only_digits"))
        }

        if enableRepeats == false {
            if Set(guess).count != guess.count {
                messages.append(String(localized: "validation.no_repeats"))
            }

            if guess.count == answerLength && guesses.contains(guess) {
                messages.append(String(localized: "validation.already_guessed"))
            }
        }

        return messages
    }

    private func saveGameToHistory(finalState: Bool, score: Int, endReason: HistoryItem.EndReason = .completed) {
        // Do not store rounds that ended before any guess was submitted.
        guard guesses.isEmpty == false || endReason == .surrender else { return }
        guard let gameStartTime else { return }
        let totalDuration = max(0, (gameEndTime ?? Date()).timeIntervalSince(gameStartTime))
        
        historyStore.add(
            finalState: finalState,
            answer: answer,
            steps: guesses.count,
            score: score,
            maxSteps: maximumGuesses,
            hardMode: enableHardMode,
            enableRepeats: enableRepeats,
            guesses: guesses,
            guessResults: guesses.map { GameLogic.encodedResult(guess: $0, answer: answer) },
            duration: totalDuration,
            hasPerGuessLimit: enablePerGuessTimeLimit,
            hasTotalTimeLimit: enableGameTimeLimit,
            perGuessLimit: perGuessTimeLimitSeconds,
            totalTimeLimit: gameTimeLimitSeconds,
            guessDurations: guessDurations,
            endReason: endReason
        )
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
            perGuessRemainingSeconds = perGuessTimeLimitSeconds
            startPerGuessTimer()
        }
        if isGameLimitActive {
            gameRemainingSeconds = gameTimeLimitSeconds
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
                    if perGuessRemainingSeconds > 0 {
                        perGuessRemainingSeconds -= 1
                    } else {
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
                    if gameRemainingSeconds > 0 {
                        gameRemainingSeconds -= 1
                    } else {
                        handleTimeLimitExpired(.game)
                    }
                }
            }
        }
    }

    private enum TimeLimitType { case perGuess, game }

    private func handleTimeLimitExpired(_ type: TimeLimitType) {
        stopAllTimers()
        gameEndTime = Date()
        gameInProgress = false
        isPaused = false
        pauseStartedAt = nil
        timeoutEndReason = type == .perGuess ? .timeoutPerGuess : .timeoutGame
        gameOverMessage = type == .perGuess
            ? localized("alert.per_guess_timeout.message", answer)
            : localized("alert.game_timeout.message", answer)
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
        isGameOver = true
    }

    private func restartPerGuessTimeLimit() {
        perGuessRemainingSeconds = perGuessTimeLimitSeconds
    }

    private func togglePause() {
        guard isAnyTimerActive, isWon == false, isGameOver == false else { return }
        if isPaused {
            if let pauseStartedAt {
                // Shift timestamps forward so paused time is excluded from durations/scoring.
                let pauseDuration = Date().timeIntervalSince(pauseStartedAt)
                gameStartTime = gameStartTime?.addingTimeInterval(pauseDuration)
                lastGuessTime = lastGuessTime?.addingTimeInterval(pauseDuration)
            }
            pauseStartedAt = nil
            isPaused = false
            resumeTimeLimitsAfterPause()
            focusGuessField()
        } else {
            stopAllTimers()
            pauseStartedAt = Date()
            isPaused = true
        }
    }

    private func surrenderGame() {
        stopAllTimers()
        gameEndTime = Date()
        gameInProgress = false
        timeoutEndReason = .surrender
        gameOverMessage = localized("alert.surrender.message", answer)
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
        isGameOver = true
    }

    private func focusGuessField(selectAll: Bool = false) {
        DispatchQueue.main.async {
            isGuessFieldFocused = true
            if selectAll { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
        }
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
    }

    private var gameTab: some View {
        VStack(spacing: 0) {
            headerSection
            inputSection
            guessesListSection
            footerSection
        }
        .onAppear { if answer.isEmpty { startNewGame() } }
        .onChange(of: enablePerGuessTimeLimit) {
            startNewGame()
        }
        .onChange(of: enableGameTimeLimit) {
            startNewGame()
        }
        .onChange(of: guess) {
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
        .alert(localized("game.alert.win.title"), isPresented: $isWon) {
            Button(localized("common.action.play_again")) {
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
                startNewGame()
            }
            Button(localized("common.action.ok")) {
                isDisabledSubmitButton = true
                saveGameToHistory(finalState: true, score: scoreValue, endReason: .completed)
            }
        } message: { Text(localized("alert.win.message", guesses.count, scoreValue)) }
        .alert(localized("game.alert.lose.title"), isPresented: $isGameOver) {
            Button(localized("common.action.play_again")) {
                saveGameToHistory(finalState: false, score: 0, endReason: timeoutEndReason ?? .completed)
                startNewGame()
            }
            Button(localized("common.action.ok")) {
                isDisabledSubmitButton = true
                showAnswer = localized("game.answer_was", answer)
                saveGameToHistory(finalState: false, score: 0, endReason: timeoutEndReason ?? .completed)
            }
        } message: { Text(gameOverMessage.isEmpty ? localized("alert.lose.message", answer) : gameOverMessage) }
        .tabItem { Label(localized("tab.game"), systemImage: "gamecontroller") }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(gameModeMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            HStack(spacing: 12) {
                Text(localized("game.header.avg_steps", stats.averageSteps, ))
                    .padding(.trailing, 10)
                Text(localized("game.header.best_streak", stats.bestWinStreak))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                Text(localized("settings.theme.label"))
                Image(selectedBullAssetName).resizable().frame(width: 20, height: 20)
                Image(selectedCowAssetName).resizable().frame(width: 20, height: 20)
            }
            .padding(.bottom, 4)

            
            if isAnyTimerActive {
                HStack(spacing: 12) {
                    if isPerGuessLimitActive {
                        Label(GameLogic.formatTime(perGuessRemainingSeconds), systemImage: "timer")
                    }
                    if isGameLimitActive {
                        Label(GameLogic.formatTime(gameRemainingSeconds), systemImage: "hourglass")
                    }
                    Button(isPaused ? localized("game.timer.resume") : localized("game.timer.pause")) {
                        togglePause()
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.orange)
            }
        }
        .padding(.top, 12)
    }

    private var inputSection: some View {
        VStack {
            HStack {
                TextField(localized("game.input.placeholder"), text: $guess)
                    .focused($isGuessFieldFocused)
                    .onSubmit(submitGuess)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isPaused)

                Button(localized("game.input.submit"), action: submitGuess)
                    .disabled(isDisabledSubmitButton || isPaused)
                   // .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 60)
            
            Text(guessInputErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(minHeight: 14, alignment: .top)
        }
        .padding(.vertical, 10)
    }

    private var guessesListSection: some View {
        List(0..<guesses.count, id: \.self) { index in
            let attempt = guesses[index]
            let duration = index < guessDurations.count ? guessDurations[index] : 0
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(attempt).monospaced()
                    Text(GameLogic.formatDuration(TimeInterval(duration)))
                        .font(.system(size: 9))
                        .listStyle(.sidebar)
                }
                Spacer()
                bullCowResultView(for: attempt)
            }
        }
        .listStyle(.sidebar)
    }

    private var footerSection: some View {
        VStack {
            if showGuessCount {
                Text(localized("Guesses: %lld/%lld", guesses.count, maximumGuesses))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }

            HStack(spacing: 12) {
                Button(localized("game.action.surrender")) {
                    showSurrenderConfirmation = true
                }
                .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.0))
                .disabled(isWon || isGameOver)

                Button(localized("game.action.restart"), action: startNewGame)
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func bullCowResultView(for guess: String) -> some View {
        let counts = GameLogic.bullCowCounts(guess: guess, answer: answer)
        HStack(spacing: 4) {
            ForEach(0..<counts.bulls, id: \.self) { _ in Image(selectedBullAssetName).resizable().frame(width: 24, height: 24) }
            ForEach(0..<counts.cows, id: \.self) { _ in Image(selectedCowAssetName).resizable().frame(width: 24, height: 24) }
            if counts.bulls == 0 && counts.cows == 0 { Text("0").foregroundStyle(.secondary) }
        }
    }
        
}
