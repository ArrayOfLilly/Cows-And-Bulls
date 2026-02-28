//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI

struct ContentView: View {
    @AppStorage("maximumGuesses") var maximumGuesses = 10
    @AppStorage("showGuessCount") var showGuessCount = false
    @AppStorage("answerLength") var answerLength = 4
    @AppStorage("enableHardMode") var enableHardMode = false
    @AppStorage("enableRepeats") var enableRepeats = false

    @EnvironmentObject var historyStore: HistoryStore

    @State private var answer = ""
    @State private var guesses = [String]()
    @State private var guess = ""
    @State private var currentRound = 0
    @State private var isWon = false
    @State private var isGameOver = false
    @State private var isDisabledSubmitButton = false
    @State private var guessInputErrorMessage = ""
    @State private var showAnswer = ""
    private var score: Int {
        get {
            var score = 0

            if guesses.count == maximumGuesses {
                score = 1
            } else if Double(guesses.count) < Double(maximumGuesses) * 0.5 {
                score = 25
            } else if Double(guesses.count) < Double(maximumGuesses) * 0.625 {
                score = 20
            } else if Double(guesses.count) < Double(maximumGuesses) * 0.75 {
                score = 15
            } else if Double(guesses.count) < Double(maximumGuesses) * 0.9 {
                score = 10
            } else if Double(guesses.count) == 1 {
                score = 100
            } else {
                score = 5
            }

            score = answerLength * score
            if enableHardMode {
                score *= 2
            }
            return score
        }
    }

    func resetGuessInputErrorMessage() {
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

    func startNewGame() {
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

        for i in 0..<answerLength {
            answer.append(String(numbers[i]))
        }
    }

    func submitGuess() {
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

        if result(for: guess) == String(Array(repeating: "🟢", count: answerLength)) {
            isWon = true
        }

        if currentRound == maximumGuesses && result(for: guess) != String(Array(repeating: "🟢", count: answerLength)) {
            isGameOver = true
        }

        guess = ""
    }

    // LeetCode version
    func result(for guess: String) -> String {
        let guessLetters = Array(guess)
        let answerLetters = Array(answer)

        var bulls = 0
        var cows = 0

        var answerLetterCount: [Character: Int] = [:]
        var guessLetterCount: [Character: Int] = [:]

        for i in 0..<answerLetters.count {
            if answerLetters[i] == guessLetters[i] {
                bulls += 1
            } else {
                answerLetterCount[answerLetters[i], default: 0] += 1
                guessLetterCount[guessLetters[i], default: 0] += 1
            }
        }

        for (char, letterCount) in answerLetterCount {
            cows += min(letterCount, guessLetterCount[char] ?? 0)
        }

        return String(Array(repeating: "🟢", count: bulls) + Array(repeating: "⚪", count: cows))
    }

    var body: some View {
        TabView {
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Text("Game mode:")
                            .font(Font.caption)
                            .fontWeight(Font.Weight.semibold)
                            .help("Shows the difficulty of the game and whether numbers can be repeated.")
                        Text("\(enableHardMode ? "hard" : "normal") with \(enableRepeats ? "repeats" : "unique numbers")")
                            .font(Font.caption)
                            .foregroundColor(.secondary)
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
                        .foregroundStyle(Color.red)
                    Text(showAnswer)
                        .foregroundStyle(Color.blue)
                }
                    .padding(40)

                List(0..<guesses.count, id: \.self) { index in
                    let guess = guesses[index]
                    let shouldShowResult = (enableHardMode == false) || (enableHardMode && index == 0)

                    HStack {
                        Text(guess)
                        Spacer()

                        if shouldShowResult {
                            Text(result(for: guess))
                        }
                    }
                }
                    .listStyle(.sidebar)
                    .help("List of your guesses and the result for each one in descending order.")

                if showGuessCount {
                    Text("Guesses: \(guesses.count)/\(maximumGuesses)")
                        .padding()
                        .help("Shows how many guesses you've made so far and how many you have left.")
                }

                Button("Restart Game") {
                    startNewGame()
                }
                    .foregroundStyle(Color.blue)
                    .help("Restarts the game and clears all your guesses.")
                    .padding(.top, 2)
                    .padding(.bottom, 20)
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

                    historyStore.add(
                        finalState: true,
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
            } message: {
                Text("Congratulations! You won in \(guesses.count) steps, you got \(score) points.")
            }
                .alert("Game Over!", isPresented: $isGameOver) {
                Button("OK") {
                    isDisabledSubmitButton = true
                    showAnswer = "The answer was: \(answer)."

                    historyStore.add(
                        finalState: false,
                        answer: answer,
                        steps: guesses.count,
                        score: 0,
                        maxSteps: maximumGuesses,
                        hardMode: enableHardMode,
                        enableRepeats: enableRepeats,
                        guesses: guesses,
                        guessResults: guesses.map { result(for: $0) }
                    )
                }
            } message: {
                Text("You lost, the correct answer is: \(answer).")
            }
                .touchBar {
                HStack {
                    Text("Guesses: \(guesses.count)") .touchBarItemPrincipal()
                    Spacer(minLength: 200)
                }
            }
                .tabItem {
                Label("Game", systemImage: "gamecontroller")
            }

            HistoryView()

        }
            .frame(width: 300)
            .frame(minHeight: 500, idealHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
    }
}

#Preview {
    ContentView()
        .environmentObject(HistoryStore())
}
