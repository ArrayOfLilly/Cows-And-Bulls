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
    @FocusState private var isGuessFieldFocused: Bool

    // MARK: - Computed Values

    private var score: Int {
        GameLogic.score(
            guessCount: guesses.count,
            maximumGuesses: maximumGuesses,
            answerLength: answerLength,
            hardMode: enableHardMode
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
            SoundPlayer.shared.play(.win, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isWon = true
        } else if currentRound == maximumGuesses {
            SoundPlayer.shared.play(.lose, enabled: enableSoundEffects, volume: soundEffectsVolume)
            isGameOver = true
        } else {
            SoundPlayer.shared.play(.submit, enabled: enableSoundEffects, volume: soundEffectsVolume)
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

    // MARK: - View

    var body: some View {
        TabView {
            gameTab
            HistoryView()
            StatisticView()
        }
        .frame(minWidth: 520, idealWidth: 560)
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
            Text(localized("alert.lose.message", answer))
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
                    .help("Shows the difficulty of the game and whether numbers can be repeated.")
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
                    .help("Type a \(answerLength)-digit \(enableRepeats ? "" : "unique") number here.")

                Button("Go", action: submitGuess)
                    .disabled(isDisabledSubmitButton)
                    .help("Submit your guess here.")
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
        .help("List of your guesses and the result for each one in descending order.")
    }

    @ViewBuilder
    private var guessCounterSection: some View {
        if showGuessCount {
            Text("Guesses: \(guesses.count)/\(maximumGuesses)")
                .padding()
                .help("Shows how many guesses you've made so far and how many you have left.")
        }
    }

    private var restartButton: some View {
        Button("Restart Game") {
            startNewGame()
        }
        .foregroundStyle(.blue)
        .help("Restarts the game and clears all your guesses.")
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
