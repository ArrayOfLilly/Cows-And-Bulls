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
    
    @FocusState private var isGuessFieldFocused: Bool

    // MARK: - Computed Properties

    private var stats: StatisticsLogic {
        StatisticsLogic(items: historyStore.items)
    }

    private var scoreValue: Int {
        GameLogic.score(
            codeLength: answerLength,
            allowRepeats: enableRepeats,
            hardMode: enableHardMode,
            hidesRemainingGuesses: showGuessCount == false,
            maxGuesses: maximumGuesses,
            usedGuesses: guesses.count,
            perMoveTimeLimit: isPerGuessLimitActive ? TimeInterval(perGuessTimeLimitSeconds) : 0,
            totalTimeLimit: isGameLimitActive ? TimeInterval(gameTimeLimitSeconds) : 0
        )
    }

    private var isPerGuessLimitActive: Bool { enablePerGuessTimeLimit && perGuessTimeLimitSeconds > 0 }
    private var isGameLimitActive: Bool { enableGameTimeLimit && gameTimeLimitSeconds > 0 }
    private var isAnyTimerActive: Bool { isPerGuessLimitActive || isGameLimitActive }
    
    private var gameModeMessage: String {
        var message = localized("Game mode:") + " "
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
        
        // Mark starting timestamps
        let now = Date()
        gameStartTime = now
        lastGuessTime = now
        
        startTimeLimits()
        focusGuessField()
    }

    private func submitGuess() {
        guessInputErrorMessage = ""
        if let validationError = GameLogic.validateGuess(
            guess: guess,
            answerLength: answerLength,
            guesses: guesses,
            allowRepeats: enableRepeats
        ) {
            guessInputErrorMessage = validationError
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
            SoundPlayer.shared.play(.win, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isWon = true
        } else if currentRound == maximumGuesses {
            stopAllTimers()
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

    private func saveGameToHistory(finalState: Bool, score: Int) {
        guard guesses.count > 0 else { return }
        let totalDuration = lastGuessTime!.timeIntervalSince(gameStartTime!)
        
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
            guessDurations: guessDurations
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
        gameOverMessage = type == .perGuess
            ? localized("alert.per_guess_timeout.message", answer)
            : localized("alert.game_timeout.message", answer)
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
        isGameOver = true
    }

    private func restartPerGuessTimeLimit() {
        perGuessRemainingSeconds = perGuessTimeLimitSeconds
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
        .alert("You Won!", isPresented: $isWon) {
            Button("Play Again") {
                saveGameToHistory(finalState: true, score: scoreValue)
                startNewGame()
            }
            Button("OK") {
                isDisabledSubmitButton = true
                saveGameToHistory(finalState: true, score: scoreValue)
            }
        } message: { Text(localized("alert.win.message", guesses.count, scoreValue)) }
        .alert("Game Over!", isPresented: $isGameOver) {
            Button("Play Again") {
                saveGameToHistory(finalState: false, score: 0)
                startNewGame()
            }
            Button("OK") {
                isDisabledSubmitButton = true
                showAnswer = localized("game.answer_was", answer)
                saveGameToHistory(finalState: false, score: 0)
            }
        } message: { Text(gameOverMessage.isEmpty ? localized("alert.lose.message", answer) : gameOverMessage) }
        .tabItem { Label("Game", systemImage: "gamecontroller") }
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
                Text(localized("Theme"))
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
                TextField(localized("Enter a guess…"), text: $guess)
                    .focused($isGuessFieldFocused)
                    .onSubmit(submitGuess)
                    .textFieldStyle(.roundedBorder)

                Button("Go", action: submitGuess)
                    .disabled(isDisabledSubmitButton)
                   // .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 60)
            
            Text(guessInputErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(height: 14)
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
                Text("Guesses: \(guesses.count)/\(maximumGuesses)")
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }
                
            Button("Restart Game", action: startNewGame)
                .foregroundStyle(.blue)
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

