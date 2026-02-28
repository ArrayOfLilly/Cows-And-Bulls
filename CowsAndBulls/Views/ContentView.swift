//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI

struct ContentView: View {
    @AppStorage("maximumGuesses") private var maximumGuesses = 10
    @AppStorage("showGuessCount") private var showGuessCount = false
    @AppStorage("answerLength") private var answerLength = 4
    @AppStorage("enableHardMode") private var enableHardMode = false
    @AppStorage("enableRepeats") private var enableRepeats = false

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

    // MARK: - Computed Values

    private var score: Int {
        var computedScore = 0

        if guesses.count == maximumGuesses {
            computedScore = 1
        } else if Double(guesses.count) < Double(maximumGuesses) * 0.5 {
            computedScore = 25
        } else if Double(guesses.count) < Double(maximumGuesses) * 0.625 {
            computedScore = 20
        } else if Double(guesses.count) < Double(maximumGuesses) * 0.75 {
            computedScore = 15
        } else if Double(guesses.count) < Double(maximumGuesses) * 0.9 {
            computedScore = 10
        } else if Double(guesses.count) == 1 {
            computedScore = 100
        } else {
            computedScore = 5
        }

        computedScore = answerLength * computedScore
        if enableHardMode {
            computedScore *= 2
        }

        return computedScore
    }

    private var winningResult: String {
        String(Array(repeating: "🟢", count: answerLength))
    }

    private var gameModeText: String {
        "\(enableHardMode ? "hard" : "normal") with \(enableRepeats ? "repeats" : "unique numbers")"
    }

    // MARK: - Game Logic

    private func resetGuessInputErrorMessage() {
        guard answerLength >= 3 && answerLength <= 8 else { return }
        guard guess.count == answerLength else { return }

        if enableRepeats == false {
            guard Set(guess).count == answerLength else { return }
        }

        guard guesses.contains(guess) == false else { return }

        let badCharacters = CharacterSet(charactersIn: "0123456789").inverted
        guard guess.rangeOfCharacter(from: badCharacters) == nil else { return }

        guessInputErrorMessage = ""
    }

    private func startNewGame() {
        resetGuessInputErrorMessage()

        guard answerLength >= 3 && answerLength <= 8 else {
            guessInputErrorMessage = "Answer length must be 3...8"
            return
        }

        showAnswer = ""
        guess = ""
        guesses.removeAll()
        answer = ""
        currentRound = 0
        isDisabledSubmitButton = false

        let numbers = (0...9).shuffled()
        for index in 0..<answerLength {
            answer.append(String(numbers[index]))
        }
    }

    private func submitGuess() {
        resetGuessInputErrorMessage()

        guard guess.count == answerLength else {
            guessInputErrorMessage = "Answer length must be \(answerLength)"
            return
        }

        if enableRepeats == false {
            guard Set(guess).count == answerLength else {
                guessInputErrorMessage = "Guesses must not contain repeated digits"
                return
            }
            guard guesses.contains(guess) == false else {
                guessInputErrorMessage = "You already guessed this sequence."
                return
            }
        }

        let badCharacters = CharacterSet(charactersIn: "0123456789").inverted
        guard guess.rangeOfCharacter(from: badCharacters) == nil else {
            guessInputErrorMessage = "Guesses must only contain digits"
            return
        }

        withAnimation {
            guesses.insert(guess, at: 0)
        }
        currentRound += 1

        if result(for: guess) == winningResult {
            isWon = true
        }

        if currentRound == maximumGuesses && result(for: guess) != winningResult {
            isGameOver = true
        }

        guess = ""
    }

    // LeetCode version
    private func result(for guess: String) -> String {
        let guessLetters = Array(guess)
        let answerLetters = Array(answer)

        var bulls = 0
        var cows = 0

        var answerLetterCount: [Character: Int] = [:]
        var guessLetterCount: [Character: Int] = [:]

        for index in 0..<answerLetters.count {
            if answerLetters[index] == guessLetters[index] {
                bulls += 1
            } else {
                answerLetterCount[answerLetters[index], default: 0] += 1
                guessLetterCount[guessLetters[index], default: 0] += 1
            }
        }

        for (char, letterCount) in answerLetterCount {
            cows += min(letterCount, guessLetterCount[char] ?? 0)
        }

        return String(Array(repeating: "🟢", count: bulls) + Array(repeating: "⚪", count: cows))
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

    // MARK: - View

    var body: some View {
        TabView {
            gameTab
            HistoryView()
            StatisticView()
        }
        .frame(minWidth: 430, idealWidth: 460)
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
            Button("OK") {
                isDisabledSubmitButton = true
                saveGameToHistory(finalState: true, score: score)
            }
        } message: {
            Text("Congratulations! You won in \(guesses.count) steps, you got \(score) points.")
        }
        .alert("Game Over!", isPresented: $isGameOver) {
            Button("OK") {
                isDisabledSubmitButton = true
                showAnswer = "The answer was: \(answer)."
                saveGameToHistory(finalState: false, score: 0)
            }
        } message: {
            Text("You lost, the correct answer is: \(answer).")
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
            .padding(.bottom, 10)

            HStack {
                TextField("Enter a guess…", text: $guess)
                    .onChange(of: guess) {
                        resetGuessInputErrorMessage()
                    }
                    .onSubmit(submitGuess)
                    .help("Type a \(answerLength)-digit \(enableRepeats ? "" : "unique") number here.")

                Button("Go", action: submitGuess)
                    .disabled(isDisabledSubmitButton)
                    .help("Submit your guess here.")
            }

            Text(guessInputErrorMessage)
                .foregroundStyle(.red)
            Text(showAnswer)
                .foregroundStyle(.blue)
        }
        .padding(40)
    }

    private var guessesListSection: some View {
        List(0..<guesses.count, id: \.self) { index in
            let attempt = guesses[index]
            let shouldShowResult = (enableHardMode == false) || (enableHardMode && index == 0)

            HStack {
                Text(attempt)
                Spacer()

                if shouldShowResult {
                    Text(result(for: attempt))
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
}

#Preview {
    ContentView()
        .environmentObject(HistoryStore())
}
