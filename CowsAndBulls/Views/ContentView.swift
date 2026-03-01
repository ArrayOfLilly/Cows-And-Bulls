//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI
import AppKit

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
    @FocusState private var isGuessFieldFocused: Bool

    // MARK: - Computed Values

    private var score: Int {
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

    private var gameModeText: String {
        localized(
            "game.mode.format",
            localized(enableHardMode ? "game.mode.hard" : "game.mode.normal"),
            localized(enableRepeats ? "game.mode.repeats" : "game.mode.unique")
        )
    }

    private var averageStepsAllGames: Double {
        let items = historyStore.items
        guard items.isEmpty == false else { return 0 }
        let totalSteps = items.reduce(0) { $0 + $1.steps }
        return Double(totalSteps) / Double(items.count)
    }

    private var isPerGuessLimitActive: Bool {
        enablePerGuessTimeLimit && perGuessTimeLimitSeconds > 0
    }

    private var isGameLimitActive: Bool {
        enableGameTimeLimit && gameTimeLimitSeconds > 0
    }

    private var isAnyTimerActive: Bool {
        isPerGuessLimitActive || isGameLimitActive
    }

    private enum TimeLimitType {
        case perGuess
        case game
    }

    private var bestWinStreak: Int {
        var current = 0
        var best = 0

        for item in historyStore.items {
            if item.finalState {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return best
    }

    // MARK: - Game Logic

    private func resetGuessInputErrorMessage() {
        guard answerLength >= 3 && answerLength <= 8 else { return }
        if GameLogic.validateGuess(
            guess: guess,
            answerLength: answerLength,
            guesses: guesses,
            allowRepeats: enableRepeats
        ) == nil {
            guessInputErrorMessage = ""
        }
    }

    private func startNewGame() {
        stopAllTimers()
        resetGuessInputErrorMessage()

        guard answerLength >= 3 && answerLength <= 8 else {
            guessInputErrorMessage = String(localized: "validation.answer_length_range")
            return
        }

        showAnswer = ""
        guess = ""
        guesses.removeAll()
        answer = GameLogic.generateAnswer(length: answerLength, allowRepeats: enableRepeats)
        currentRound = 0
        isDisabledSubmitButton = false
        gameOverMessage = ""
        startTimeLimits()
        focusGuessField()
    }

    private func submitGuess() {
        resetGuessInputErrorMessage()

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

        let counts = bullCowCounts(for: guess)

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

    private func bullCowCounts(for guess: String) -> (bulls: Int, cows: Int) {
        GameLogic.bullCowCounts(guess: guess, answer: answer)
    }

    private func result(for guess: String) -> String {
        GameLogic.encodedResult(guess: guess, answer: answer)
    }

    private func saveGameToHistory(finalState: Bool, score: Int) {
        historyStore.add(
            finalState: finalState,
            answer: answer,
            steps: guesses.count,
            score: score,
            maxSteps: maximumGuesses,
            hardMode: enableHardMode,
            enableRepeats: enableRepeats,
            guesses: guesses,
            guessResults: guesses.map { result(for: $0) }
        )
    }

    private func focusGuessField(selectAll: Bool = false) {
        DispatchQueue.main.async {
            isGuessFieldFocused = true

            if selectAll {
                DispatchQueue.main.async {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
            }
        }
    }

    private func stopPerGuessTimer() {
        perGuessTimerTask?.cancel()
        perGuessTimerTask = nil
    }

    private func stopGameTimer() {
        gameTimerTask?.cancel()
        gameTimerTask = nil
    }

    private func stopAllTimers() {
        stopPerGuessTimer()
        stopGameTimer()
    }

    private func startTimeLimits() {
        if isPerGuessLimitActive {
            perGuessRemainingSeconds = perGuessTimeLimitSeconds
            startPerGuessTimer()
        } else {
            perGuessRemainingSeconds = 0
            stopPerGuessTimer()
        }

        if isGameLimitActive {
            gameRemainingSeconds = gameTimeLimitSeconds
            startGameTimer()
        } else {
            gameRemainingSeconds = 0
            stopGameTimer()
        }
    }

    private func restartPerGuessTimeLimit() {
        guard isPerGuessLimitActive, isWon == false, isGameOver == false else { return }
        perGuessRemainingSeconds = perGuessTimeLimitSeconds
        startPerGuessTimer()
    }

    private func applyTimeLimitSettingsImmediately() {
        guard isWon == false, isGameOver == false else {
            stopAllTimers()
            return
        }
        startTimeLimits()
    }

    private func startPerGuessTimer() {
        stopPerGuessTimer()
        perGuessTimerTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }

                var expired = false
                await MainActor.run {
                    guard isWon == false, isGameOver == false, isPerGuessLimitActive else { return }
                    if perGuessRemainingSeconds > 0 {
                        perGuessRemainingSeconds -= 1
                    }
                    if perGuessRemainingSeconds <= 0 {
                        expired = true
                    }
                }

                if expired {
                    await MainActor.run {
                        handleTimeLimitExpired(.perGuess)
                    }
                    return
                }
            }
        }
    }

    private func startGameTimer() {
        stopGameTimer()
        gameTimerTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }

                var expired = false
                await MainActor.run {
                    guard isWon == false, isGameOver == false, isGameLimitActive else { return }
                    if gameRemainingSeconds > 0 {
                        gameRemainingSeconds -= 1
                    }
                    if gameRemainingSeconds <= 0 {
                        expired = true
                    }
                }

                if expired {
                    await MainActor.run {
                        handleTimeLimitExpired(.game)
                    }
                    return
                }
            }
        }
    }

    private func handleTimeLimitExpired(_ type: TimeLimitType) {
        guard isWon == false, isGameOver == false else { return }
        stopAllTimers()
        gameOverMessage = type == .perGuess
            ? localized("alert.per_guess_timeout.message", answer)
            : localized("alert.game_timeout.message", answer)
        SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
        isGameOver = true
    }

    private func formattedTimer(_ totalSeconds: Int) -> String {
        let safeSeconds = max(0, totalSeconds)
        return String(format: "%02d:%02d", safeSeconds / 60, safeSeconds % 60)
    }

    // MARK: - View

    var body: some View {
        TabView {
            gameTab
            HistoryView()
            StatisticView()
        }
        .frame(minWidth: 470, idealWidth: 510)
        .frame(minHeight: 500, idealHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
    }

    private var gameTab: some View {
        VStack(spacing: 0) {
            headerAndInputSection
            guessesListSection
            guessCounterSection
            restartButton
        }
        .navigationTitle("Cows and Bulls")
        .frame(minHeight: 350, maxHeight: .infinity)
        .onAppear(perform: startNewGame)
        .onChange(of: answerLength) {
            startNewGame()
        }
        .onChange(of: enablePerGuessTimeLimit) {
            applyTimeLimitSettingsImmediately()
        }
        .onChange(of: enableGameTimeLimit) {
            applyTimeLimitSettingsImmediately()
        }
        .onChange(of: perGuessTimeLimitSeconds) {
            applyTimeLimitSettingsImmediately()
        }
        .onChange(of: gameTimeLimitSeconds) {
            applyTimeLimitSettingsImmediately()
        }
        .alert("You Won!", isPresented: $isWon) {
            Button("Play Again") {
                saveGameToHistory(finalState: true, score: score)
                startNewGame()
            }
            Button("OK") {
                isDisabledSubmitButton = true
                saveGameToHistory(finalState: true, score: score)
            }
        } message: {
            Text(localized("alert.win.message", guesses.count, score))
        }
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
        } message: {
            Text(gameOverMessage.isEmpty ? localized("alert.lose.message", answer) : gameOverMessage)
        }
        .touchBar {
            HStack {
                Text("Guesses: \(guesses.count)")
                    .touchBarItemPrincipal()
                Spacer(minLength: 200)
            }
        }
        .tabItem {
            Label("Game", systemImage: "gamecontroller")
        }
    }

    private var headerAndInputSection: some View {
        VStack {
            HStack {
                Text("Game mode:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .help(localized("help.content.game_mode"))
                Text(gameModeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)

            HStack(spacing: 16) {
                Text(localized("game.header.best_streak", bestWinStreak))
                Text(localized("game.header.avg_steps", averageStepsAllGames))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if isAnyTimerActive {
                HStack(spacing: 10) {
                    if isPerGuessLimitActive {
                        Text(localized("timer.per_guess.remaining", formattedTimer(perGuessRemainingSeconds)))
                    }
                    if isGameLimitActive {
                        Text(localized("timer.game.remaining", formattedTimer(gameRemainingSeconds)))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text("Theme:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(selectedBullAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Image(selectedCowAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }

            HStack {
                TextField("Enter a guess…", text: $guess)
                    .focused($isGuessFieldFocused)
                    .onChange(of: guess) {
                        resetGuessInputErrorMessage()
                    }
                    .onSubmit(submitGuess)
                    .help(localized("help.content.guess_field"))

                Button("Go", action: submitGuess)
                    .disabled(isDisabledSubmitButton)
                    .help(localized("Submit your guess here."))
            }
            .padding(.horizontal, 70)
            .padding(.vertical, 10)

            Text(guessInputErrorMessage)
                .foregroundStyle(.red)
            Text(showAnswer)
                .foregroundStyle(.blue)
        }
    }

    private var guessesListSection: some View {
        List(0..<guesses.count, id: \.self) { index in
            let attempt = guesses[index]
            let shouldShowResult = (enableHardMode == false) || (enableHardMode && index == 0)

            HStack {
                Text(attempt)
                Spacer()

                if shouldShowResult {
                    bullCowResultView(for: attempt)
                }
            }
            .padding(.horizontal, 24)
        }
        .listStyle(.sidebar)
        .help(localized("List of your guesses and the result for each one in descending order."))
    }

    @ViewBuilder
    private var guessCounterSection: some View {
        if showGuessCount {
            Text("Guesses: \(guesses.count)/\(maximumGuesses)")
                .padding()
                .help(localized("Shows how many guesses you've made so far and how many you have left."))
        }
    }

    private var restartButton: some View {
        Button("Restart Game") {
            startNewGame()
        }
        .foregroundStyle(.blue)
        .help(localized("Restarts the game and clears all your guesses."))
        .padding(.top, 2)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func bullCowResultView(for guess: String) -> some View {
        let counts = bullCowCounts(for: guess)

        if counts.bulls == 0 && counts.cows == 0 {
            Text("0")
        } else {
            HStack(spacing: 4) {
                ForEach(0..<counts.bulls, id: \.self) { _ in
                    Image(selectedBullAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                ForEach(0..<counts.cows, id: \.self) { _ in
                    Image(selectedCowAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HistoryStore())
}
