//
//  GameplayStore.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 11..
//

import Foundation
internal import Combine

@MainActor
final class GameplayStore: ObservableObject {
    enum SubmissionResult: Equatable {
        case invalid
        case submitted
        case won
        case lost
    }

    @Published var answer = ""
    @Published var guesses: [String] = []
    @Published var guess = ""
    @Published private(set) var currentRound = 0
    @Published var isWon = false
    @Published var isGameOver = false
    @Published var isDisabledSubmitButton = false
    @Published var guessInputErrorMessage = ""
    @Published var showAnswer = ""
    @Published var gameOverMessage = ""

    func startNewGame(settings: ProfileSettings) {
        reset()

        guard (3...8).contains(settings.answerLength) else {
            guessInputErrorMessage = String(localized: "validation.answer_length_range")
            return
        }
        answer = GameLogic.generateAnswer(length: settings.answerLength, allowRepeats: settings.enableRepeats)
        isDisabledSubmitButton = false
        guessInputErrorMessage = ""
    }

    func reset() {
        answer = ""
        guesses.removeAll()
        guess = ""
        currentRound = 0
        isWon = false
        isGameOver = false
        isDisabledSubmitButton = true
        guessInputErrorMessage = ""
        showAnswer = ""
        gameOverMessage = ""
    }

    func updateLiveGuessValidation(settings: ProfileSettings) {
        guard guess.isEmpty == false else {
            guessInputErrorMessage = ""
            return
        }
        let errors = validationErrors(for: guess, settings: settings, includeLengthError: false)
        guessInputErrorMessage = errors.joined(separator: "\n")
    }

    func submitGuess(settings: ProfileSettings, gameInProgress: Bool) -> SubmissionResult {
        if gameInProgress == false || answer.isEmpty {
            let pendingGuess = guess
            startNewGame(settings: settings)
            guard answer.isEmpty == false else { return .invalid }
            guess = pendingGuess
        }

        let errors = validationErrors(for: guess, settings: settings, includeLengthError: true)
        if errors.isEmpty == false {
            guessInputErrorMessage = errors.joined(separator: "\n")
            return .invalid
        }

        let counts = GameLogic.bullCowCounts(guess: guess, answer: answer)
        guesses.insert(guess, at: 0)
        currentRound += 1

        if counts.bulls == settings.answerLength {
            isWon = true
            guess = ""
            return .won
        }

        if currentRound == settings.maximumGuesses {
            gameOverMessage = localized("alert.lose.message", answer)
            isGameOver = true
            guess = ""
            return .lost
        }

        guess = ""
        return .submitted
    }

    func presentGameOver(message: String) {
        gameOverMessage = message
        isGameOver = true
    }

    func finalizeWin() {
        isDisabledSubmitButton = true
    }

    func finalizeLoss() {
        isDisabledSubmitButton = true
        showAnswer = localized("game.answer_was", answer)
    }

    private func validationErrors(
        for guess: String,
        settings: ProfileSettings,
        includeLengthError: Bool
    ) -> [String] {
        var messages: [String] = []

        if includeLengthError && guess.count != settings.answerLength {
            if (3...8).contains(settings.answerLength) == false {
                messages.append(localized("validation.answer_length_range"))
            } else {
                messages.append(localized("validation.answer_length", settings.answerLength))
            }
        }

        let badCharacters = CharacterSet(charactersIn: "0123456789").inverted
        if guess.rangeOfCharacter(from: badCharacters) != nil {
            messages.append(String(localized: "validation.only_digits"))
        }

        if settings.enableRepeats == false {
            if Set(guess).count != guess.count {
                messages.append(String(localized: "validation.no_repeats"))
            }

            if guess.count == settings.answerLength && guesses.contains(guess) {
                messages.append(String(localized: "validation.already_guessed"))
            }
        }

        return messages
    }
}
