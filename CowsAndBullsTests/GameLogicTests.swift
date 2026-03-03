import Testing
import Foundation
@testable import Cows___Bulls

/// Suite for testing core game rules, scoring algorithms, and input validation.
struct GameLogicTests {
    
    // MARK: - Bull and Cow Counting Tests
    
    @Test("Basic Bull and Cow calculation with no duplicates")
    func bullCowCountsBasic() {
        // Guess 1234 vs Answer 1243: 1,2 correctly placed (2 Bulls), 3,4 incorrectly placed (2 Cows)
        let result = GameLogic.bullCowCounts(guess: "1234", answer: "1243")
        #expect(result.bulls == 2)
        #expect(result.cows == 2)
    }
    
    @Test("Handling zero matches (0 bulls, 0 cows)")
    func bullCowCountsNoMatches() {
        let result = GameLogic.bullCowCounts(guess: "1234", answer: "5678")
        #expect(result.bulls == 0)
        #expect(result.cows == 0)
    }
    
    @Test("Handling full match (All bulls)")
    func bullCowCountsAllBulls() {
        let result = GameLogic.bullCowCounts(guess: "1234", answer: "1234")
        #expect(result.bulls == 4)
        #expect(result.cows == 0)
    }
    
    @Test("Correct handling of repeated digits in guess vs answer")
    func bullCowCountsWithRepeats() {
        // Guess has two '1's, but answer has only one '1' at the start.
        // Result: 1 Bull (the first position), 0 Cows (no other '1' exists in the answer).
        let result = GameLogic.bullCowCounts(guess: "1123", answer: "1456")
        #expect(result.bulls == 1)
        #expect(result.cows == 0)
    }

    // MARK: - Guess Validation Tests

    @Test("Rejection of guesses with incorrect length")
    func validateGuessWrongLength() {
        let message = GameLogic.validateGuess(
            guess: "123",
            answerLength: 4,
            guesses: [],
            allowRepeats: false
        )
        // If message is not nil, the validator correctly identified the error.
        #expect(message != nil)
    }

    @Test("Rejection of repeated digits when the rules forbid them")
    func validateGuessNoRepeatsRule() {
        let message = GameLogic.validateGuess(
            guess: "1123",
            answerLength: 4,
            guesses: [],
            allowRepeats: false
        )
        #expect(message != nil)
    }
    
    @Test("Rejection of guess that has already been attempted")
    func validateGuessAlreadyGuessed() {
        let message = GameLogic.validateGuess(
            guess: "1234",
            answerLength: 4,
            guesses: ["1234"],
            allowRepeats: false
        )
        #expect(message != nil)
    }

    // MARK: - Scoring Algorithm Tests
    
    @Test("Score increase for longer code lengths (increased difficulty)")
    func scoreLengthImpact() {
        let short = GameLogic.score(codeLength: 3, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 3, perMoveTimeLimit: 0, totalTimeLimit: 0)
        let long = GameLogic.score(codeLength: 6, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 3, perMoveTimeLimit: 0, totalTimeLimit: 0)
        
        #expect(long > short)
    }

    @Test("Higher score reward for winning with fewer attempts")
    func scoreUsedGuessesImpact() {
        let efficient = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 2, perMoveTimeLimit: 0, totalTimeLimit: 0)
        let slow = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 8, perMoveTimeLimit: 0, totalTimeLimit: 0)
        
        #expect(efficient > slow)
    }

    @Test("Shorter per-guess timer increases score")
    func scorePerGuessTimerImpact() {
        let relaxed = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 4, perMoveTimeLimit: 180, totalTimeLimit: 0)
        let strict = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 4, perMoveTimeLimit: 5, totalTimeLimit: 0)

        #expect(strict > relaxed)
    }

    @Test("Shorter total game timer increases score")
    func scoreGameTimerImpact() {
        let relaxed = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 4, perMoveTimeLimit: 0, totalTimeLimit: 1800)
        let strict = GameLogic.score(codeLength: 4, allowRepeats: false, hardMode: false, hidesRemainingGuesses: false, maxGuesses: 10, usedGuesses: 4, perMoveTimeLimit: 0, totalTimeLimit: 300)

        #expect(strict > relaxed)
    }

    @Test("Time multiplier is 1.0 when no timers are enabled")
    func timeMultiplierNoTimers() {
        let value = GameLogic.timeMultiplier(
            enablePerGuess: false,
            perGuessSeconds: 0,
            enableGame: false,
            gameSeconds: 0
        )

        #expect(abs(value - 1.0) < 0.000_001)
    }

    @Test("Time multiplier reaches maximum when both timers are set to strictest limits")
    func timeMultiplierMaximumAtStrictestLimits() {
        let value = GameLogic.timeMultiplier(
            enablePerGuess: true,
            perGuessSeconds: 5,
            enableGame: true,
            gameSeconds: 300
        )

        #expect(abs(value - 2.0) < 0.000_001)
    }

    @Test("First-guess jackpot uses +10x base score")
    func firstGuessJackpotMultiplier() {
        let score = GameLogic.score(
            codeLength: 4,
            allowRepeats: false,
            hardMode: false,
            hidesRemainingGuesses: false,
            maxGuesses: 12,
            usedGuesses: 1,
            perMoveTimeLimit: 0,
            totalTimeLimit: 0
        )

        let combinations = 10 * 9 * 8 * 7
        let baseScore = log10(Double(combinations)) * 100.0
        let expected = Int((baseScore * 2.5 + baseScore * 10.0).rounded())

        #expect(score == expected)
    }

    @Test("Validation rejects non-digit input")
    func validateGuessRejectsNonDigits() {
        let message = GameLogic.validateGuess(
            guess: "12a4",
            answerLength: 4,
            guesses: [],
            allowRepeats: false
        )

        #expect(message != nil)
    }

    @Test("Validation allows repeated digits when repeats are enabled")
    func validateGuessAllowsRepeatsWhenEnabled() {
        let message = GameLogic.validateGuess(
            guess: "1123",
            answerLength: 4,
            guesses: [],
            allowRepeats: true
        )

        #expect(message == nil)
    }
}
