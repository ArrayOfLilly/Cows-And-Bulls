//
//  GameLogic.swift
//  CowsAndBulls
//

import Foundation

struct GameLogic {
    static func score(guessCount: Int, maximumGuesses: Int, answerLength: Int, hardMode: Bool) -> Int {
        var baseScore = 0

        if guessCount == 1 {
            baseScore = 100
        } else if guessCount == maximumGuesses {
            baseScore = 1
        } else if Double(guessCount) < Double(maximumGuesses) * 0.5 {
            baseScore = 25
        } else if Double(guessCount) < Double(maximumGuesses) * 0.625 {
            baseScore = 20
        } else if Double(guessCount) < Double(maximumGuesses) * 0.75 {
            baseScore = 15
        } else if Double(guessCount) < Double(maximumGuesses) * 0.9 {
            baseScore = 10
        } else {
            baseScore = 5
        }

        var finalScore = answerLength * baseScore
        if hardMode {
            finalScore *= 2
        }
        return finalScore
    }

    static func generateAnswer(length: Int, allowRepeats: Bool) -> String {
        if allowRepeats {
            return (0..<length)
                .map { _ in String(Int.random(in: 0...9)) }
                .joined()
        }

        let numbers = Array(0...9).shuffled()
        return (0..<length)
            .map { String(numbers[$0]) }
            .joined()
    }

    static func bullCowCounts(guess: String, answer: String) -> (bulls: Int, cows: Int) {
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

        for (char, count) in answerLetterCount {
            cows += min(count, guessLetterCount[char] ?? 0)
        }

        return (bulls, cows)
    }

    static func encodedResult(guess: String, answer: String) -> String {
        let counts = bullCowCounts(guess: guess, answer: answer)
        return "\(counts.bulls)|\(counts.cows)"
    }

    static func validateGuess(
        guess: String,
        answerLength: Int,
        guesses: [String],
        allowRepeats: Bool
    ) -> String? {
        guard guess.count == answerLength else {
            return localized("validation.answer_length", answerLength)
        }

        if allowRepeats == false {
            guard Set(guess).count == answerLength else {
                return String(localized: "validation.no_repeats")
            }
            guard guesses.contains(guess) == false else {
                return String(localized: "validation.already_guessed")
            }
        }

        let badCharacters = CharacterSet(charactersIn: "0123456789").inverted
        guard guess.rangeOfCharacter(from: badCharacters) == nil else {
            return String(localized: "validation.only_digits")
        }

        return nil
    }
}
