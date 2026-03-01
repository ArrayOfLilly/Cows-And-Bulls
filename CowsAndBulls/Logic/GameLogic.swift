//
//  GameLogic.swift
//  CowsAndBulls
//

import Foundation

struct GameLogic {
    static func score(
        codeLength: Int,
        allowRepeats: Bool,
        hardMode: Bool,
        hidesRemainingGuesses: Bool,
        maxGuesses: Int,
        usedGuesses: Int,
        perMoveTimeLimit: TimeInterval,
        totalTimeLimit: TimeInterval
    ) -> Int {
        func permutation(_ n: Int, _ r: Int) -> Double {
            guard r <= n else { return 0 }
            return (0..<r).reduce(1.0) { result, i in
                result * Double(n - i)
            }
        }

        let combinations: Double = allowRepeats
            ? pow(10.0, Double(codeLength))
            : permutation(10, codeLength)
        let baseScore = log10(combinations) * 100.0

        let standardGuesses = 3 * codeLength

        var difficulty: Double = 1.0
        if allowRepeats {
            difficulty *= 1.15
        }
        if hardMode {
            difficulty *= 1.40
        }
        if hidesRemainingGuesses {
            difficulty *= 1.15
        }
        if maxGuesses > 0 {
            let guessPressure = Double(standardGuesses) / Double(maxGuesses)
            difficulty *= max(1.0, guessPressure)
        }
        if perMoveTimeLimit > 0 {
            difficulty *= 1.20
        }
        if totalTimeLimit > 0 {
            difficulty *= 1.15
        }

        let performanceMultiplier = min(
            2.5,
            Double(standardGuesses) / Double(max(1, usedGuesses))
        )

        var finalScore = baseScore * difficulty * performanceMultiplier
        if usedGuesses == 1 {
            finalScore += baseScore * 3.0
        }
        return Int(finalScore.rounded())
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
