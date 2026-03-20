import Testing
import Foundation
@testable import Cows___Bulls

/// Unit tests for StatisticsLogic.
/// These tests ensure that mathematical formulas (average, win rate, etc.) 
/// calculate the correct values regardless of the data input.
@Suite("Statistics Logic Tests")
struct StatisticsTests {

    /// Helper function to create a mock history item for testing.
    /// Simplifies test code by providing default values for non-essential fields.
    private func createMockItem(
        won: Bool,
        score: Int,
        steps: Int,
        length: Int,
        hard: Bool,
        repeats: Bool,
        duration: TimeInterval = 0,
        hasPerGuessLimit: Bool = false,
        hasTotalTimeLimit: Bool = false,
        guessDurations: [Int] = [],
        endReason: HistoryItem.EndReason = .completed
    ) -> HistoryItem {
        HistoryItem(
            duration: duration,
            hasPerGuessLimit: hasPerGuessLimit,
            hasTotalTimeLimit: hasTotalTimeLimit,
            perGuessLimit: 0,
            totalTimeLimit: 0,
            guessDurations: guessDurations,
            finalState: won,
            answer: String(repeating: "1", count: length),
            steps: steps,
            score: score,
            maxSteps: 10,
            hardMode: hard,
            enableRepeats: repeats,
            guesses: [],
            guessResults: [],
            endReason: endReason
        )
    }

    @Test("Win rate calculation for a mix of wins and losses")
    func winRate() {
        // One win, one loss -> 50% win rate
        let items = [
            createMockItem(won: true, score: 100, steps: 5, length: 4, hard: false, repeats: false),
            createMockItem(won: false, score: 0, steps: 10, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)
        
        #expect(stats.winRate == 50.0)
        #expect(stats.totalGames == 2)
        #expect(stats.wonGames == 1)
        #expect(stats.lostGames == 1)
    }

    @Test("Average calculation for score and steps")
    func averages() {
        // Average: (100+200)/2 = 150, (2+4)/2 = 3
        let items = [
            createMockItem(won: true, score: 100, steps: 2, length: 4, hard: false, repeats: false),
            createMockItem(won: true, score: 200, steps: 4, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)
        
        #expect(stats.averageScore == 150.0)
        #expect(stats.averageSteps == 3.0)
    }

    @Test("Determination of most used game mode")
    func mostUsedMode() {
        // Two Hard mode games and one Normal -> Should result in .hard
        let items = [
            createMockItem(won: true, score: 100, steps: 5, length: 4, hard: true, repeats: false),
            createMockItem(won: true, score: 100, steps: 5, length: 4, hard: true, repeats: false),
            createMockItem(won: true, score: 100, steps: 5, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)
        let mode = stats.mostUsedMode
        #expect({
            if case .hard = mode { return true }
            return false
        }())
    }

    @Test("Most used length detection including logic for ties")
    func mostUsedLength() {
        // One 4-digit and one 6-digit game -> Logic picks the larger value (6) during a tie
        let items = [
            createMockItem(won: true, score: 100, steps: 5, length: 4, hard: false, repeats: false),
            createMockItem(won: true, score: 100, steps: 5, length: 6, hard: false, repeats: false),
        ]
        let stats = StatisticsLogic(items: items)
        
        #expect(stats.mostUsedLength == 6)
    }

    @Test("Average duration metrics include non-timed games too")
    func averageStepDurationWithoutPhantomZero() {
        let items = [
            createMockItem(
                won: true,
                score: 100,
                steps: 2,
                length: 4,
                hard: false,
                repeats: false,
                duration: 40,
                hasPerGuessLimit: true,
                guessDurations: [10, 20]
            ),
            createMockItem(
                won: false,
                score: 0,
                steps: 1,
                length: 4,
                hard: false,
                repeats: false,
                duration: 30,
                hasPerGuessLimit: true,
                guessDurations: [30]
            ),
            // Non-timed entries must also contribute to duration metrics.
            createMockItem(
                won: true,
                score: 50,
                steps: 3,
                length: 4,
                hard: false,
                repeats: false,
                duration: 50,
                hasPerGuessLimit: false,
                hasTotalTimeLimit: false,
                guessDurations: [40, 50]
            )
        ]
        let stats = StatisticsLogic(items: items)

        #expect(stats.averageStepDuration == 30.0)
        #expect(stats.averageStepDurationForWonGames == 30.0)
        #expect(stats.averageDuration == 40.0)
        #expect(stats.averageDurationForWonGames == 45.0)
    }

    @Test("Timeout and first-guess metrics are calculated correctly")
    func timeoutAndFirstGuessMetrics() {
        let items = [
            createMockItem(won: true, score: 300, steps: 1, length: 4, hard: false, repeats: false),
            createMockItem(won: false, score: 0, steps: 0, length: 4, hard: false, repeats: false, endReason: .timeoutPerGuess),
            createMockItem(won: false, score: 0, steps: 0, length: 4, hard: false, repeats: false, endReason: .timeoutGame),
            createMockItem(won: false, score: 0, steps: 4, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)

        #expect(stats.bestScore == 300)
        #expect(stats.firstGuessWinsCount == 1)
        #expect(stats.firstGuessWinRate == 100.0)
        #expect(stats.timeoutLossesCount == 2)
        #expect(stats.timeoutRate == 50.0)
    }

    @Test("Empty statistics return neutral values")
    func emptyStatistics() {
        let stats = StatisticsLogic(items: [])

        #expect(stats.totalGames == 0)
        #expect(stats.averageScore == 0)
        #expect(stats.averageSteps == 0)
        #expect(stats.averageStepRatio == 0)
        #expect(stats.winRate == 0)
        switch stats.mostUsedMode {
        case .none:
            break
        default:
            Issue.record("Expected mostUsedMode to be .none")
        }
        #expect(stats.mostUsedLength == nil)
        switch stats.mostUsedRepeats {
        case .none:
            break
        default:
            Issue.record("Expected mostUsedRepeats to be .none")
        }
        switch stats.mostUsedTimers {
        case .none:
            break
        default:
            Issue.record("Expected mostUsedTimers to be .none")
        }
        #expect(stats.fastestWin == nil)
    }

    @Test("Best win streak is evaluated in chronological order")
    func bestWinStreakUsesChronologicalOrder() {
        let itemsNewestFirst = [
            createMockItem(won: true, score: 20, steps: 2, length: 4, hard: false, repeats: false),
            createMockItem(won: true, score: 20, steps: 2, length: 4, hard: false, repeats: false),
            createMockItem(won: false, score: 0, steps: 4, length: 4, hard: false, repeats: false),
            createMockItem(won: true, score: 20, steps: 2, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: itemsNewestFirst)

        #expect(stats.bestWinStreak == 2)
    }

    @Test("Timed-game counters distinguish per-guess and total timers")
    func timedGameBreakdown() {
        let items = [
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasTotalTimeLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true, hasTotalTimeLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)

        #expect(stats.timedGamesCount == 3)
        #expect(stats.perGuessTimedGamesCount == 2)
        #expect(stats.perGameTimedGamesCount == 2)
    }

    @Test("Fastest win ignores losses")
    func fastestWinIgnoresLosses() {
        let items = [
            createMockItem(won: false, score: 0, steps: 4, length: 4, hard: false, repeats: false, duration: 10),
            createMockItem(won: true, score: 100, steps: 2, length: 4, hard: false, repeats: false, duration: 18),
            createMockItem(won: true, score: 100, steps: 2, length: 4, hard: false, repeats: false, duration: 12)
        ]
        let stats = StatisticsLogic(items: items)

        #expect(stats.fastestWin == 12)
    }

    @Test("Timer preference can report all timers as the most used setup")
    func mostUsedTimersAll() {
        let items = [
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true, hasTotalTimeLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true, hasTotalTimeLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true, hasTotalTimeLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false, hasPerGuessLimit: true),
            createMockItem(won: true, score: 10, steps: 1, length: 4, hard: false, repeats: false)
        ]
        let stats = StatisticsLogic(items: items)

        switch stats.mostUsedTimers {
        case .all:
            break
        default:
            Issue.record("Expected mostUsedTimers to be .all")
        }
    }
}
