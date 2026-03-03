//
//  GameLogic.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import Foundation
import SwiftUI

/// Pure game rules and scoring utilities used by the UI layer.
/// No view state is stored here, so these functions are deterministic for the same input.
struct GameLogic {

    /// Computes the final score using code complexity, active difficulty settings,
    /// and player efficiency (used guesses).
    ///
    /// Formula overview:
    /// `final = base * difficulty * performance * time + jackpotIfFirstGuess`
    ///
    /// - base: logarithmic complexity estimate from the number of possible codes
    /// - difficulty: configuration multipliers (hard mode, repeats, hidden guess count, guess pressure)
    /// - performance: rewards solving in fewer guesses, capped at 2.5x
    /// - time: optional timer-based multiplier from `timeMultiplier`
    /// - jackpot: `+ base * 10.0` when solved on the very first guess
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

        // Number of theoretical secret-code combinations under current rules.
        let combinations: Double = allowRepeats
            ? pow(10.0, Double(codeLength))
            : permutation(10, codeLength)
        // Log scaling keeps score growth manageable when code length increases.
        let baseScore = log10(combinations) * 100.0

        let standardGuesses = 3 * codeLength

        var difficulty: Double = 1.0
        if allowRepeats { difficulty *= 1.15 }
        if hardMode { difficulty *= 1.40 }
        if hidesRemainingGuesses { difficulty *= 1.15 }
        if maxGuesses > 0 {
            // Guess pressure rewards stricter guess limits, but never penalizes with <1.0.
            let guessPressure = Double(standardGuesses) / Double(maxGuesses)
            difficulty *= max(1.0, guessPressure)
        }
        
        let performanceMultiplier = min(
            2.5,
            Double(standardGuesses) / Double(max(1, usedGuesses))
        )
        let timeMult = timeMultiplier(
            enablePerGuess: perMoveTimeLimit > 0,
            perGuessSeconds: Int(perMoveTimeLimit),
            enableGame: totalTimeLimit > 0,
            gameSeconds: Int(totalTimeLimit)
        )

        var finalScore = baseScore * difficulty * performanceMultiplier * timeMult
            
        if usedGuesses == 1 {
            // First-guess jackpot is intentionally large to strongly reward perfect starts.
            finalScore += baseScore * 10.0
        }
        return Int(finalScore.rounded())
    }
    
    // MARK: - Time Difficulty Multiplier

    /// Builds a dynamic time multiplier from enabled timers.
    ///
    /// Both timer channels contribute additively to the multiplier:
    /// - per-guess timer: +0.0 ... +0.5
    /// - total-game timer: +0.0 ... +0.5
    ///
    /// Result range:
    /// - minimum: 1.0 (no timers, or loosest limits)
    /// - maximum: 2.0 (both timers active at strictest limits)
    static func timeMultiplier(
        enablePerGuess: Bool,
        perGuessSeconds: Int,
        enableGame: Bool,
        gameSeconds: Int
    ) -> Double {

        var multiplier: Double = 1.0

        // Per-guess timer contribution (strict 5s => max bonus, relaxed 180s => no bonus).
        if enablePerGuess {
            let min: Double = 5
            let max: Double = 180
            let value = Double(perGuessSeconds)

            let normalized = 1.0 - ((value - min) / (max - min))
            multiplier += normalized * 0.5   // max +50%
        }

        // Total game timer contribution (strict 300s => max bonus, relaxed 1800s => no bonus).
        if enableGame {
            let min: Double = 300
            let max: Double = 1800
            let value = Double(gameSeconds)

            let normalized = 1.0 - ((value - min) / (max - min))
            multiplier += normalized * 0.5   // max +50%
        }

        return multiplier
    }

    /// Generates a random numeric answer.
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
    

    /// Calculates how many bulls (correct digit, correct place) and cows (correct digit, wrong place).
    static func bullCowCounts(guess: String, answer: String) -> (bulls: Int, cows: Int) {
        let guessLetters = Array(guess)
        let answerLetters = Array(answer)

        var bulls = 0
        var cows = 0

        var answerLetterCount: [Character: Int] = [:]
        var guessLetterCount: [Character: Int] = [:]

        // First pass:
        // - exact-position matches are bulls
        // - non-matching digits are counted for later cow calculation
        for index in 0..<answerLetters.count {
            if answerLetters[index] == guessLetters[index] {
                bulls += 1
            } else {
                answerLetterCount[answerLetters[index], default: 0] += 1
                guessLetterCount[guessLetters[index], default: 0] += 1
            }
        }

        // Second pass:
        // cows are limited by the overlap of remaining digit frequencies.
        for (char, count) in answerLetterCount {
            cows += min(count, guessLetterCount[char] ?? 0)
        }

        return (bulls, cows)
    }

    /// Returns the bull/cow result in "B|C" string format.
    static func encodedResult(guess: String, answer: String) -> String {
        let counts = bullCowCounts(guess: guess, answer: answer)
        return "\(counts.bulls)|\(counts.cows)"
    }
    
    /// Formats seconds into a MM:SS string representation.
    static func formatTime(_ totalSeconds: Int) -> String {
        let safeSeconds = max(0, totalSeconds)
        let minutes = safeSeconds / 60
        let seconds = safeSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formats a duration into a (x.x sec) string for individual guess feedback.
    static func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 10 {
            return String(format: "(%.1f sec)", seconds)
        } else {
            return String(format: "(%d sec)", Int(seconds.rounded()))
        }
    }

    /// Validates user input for length, digits, and repeats.
    static func validateGuess(
        guess: String,
        answerLength: Int,
        guesses: [String],
        allowRepeats: Bool
    ) -> String? {
        // Keep validation order deterministic so users always get predictable feedback.
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
