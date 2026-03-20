import Foundation

/// Pure logic structure for calculating game statistics.
/// This component is decoupled from the UI (SwiftUI), making it fast and
/// highly testable as it only processes data without side effects.
struct StatisticsLogic {
    /// The collection of historical game results to process.
    let items: [HistoryItem]

    // MARK: - Basic Counters

    var totalGames: Int { items.count }
    var wonGames: Int { items.filter { $0.finalState }.count }
    var lostGames: Int { totalGames - wonGames }
    var totalScore: Int { items.reduce(0) { $0 + $1.score } }
    var bestScore: Int { items.map(\.score).max() ?? 0 }
    var totalSteps: Int { items.reduce(0) { $0 + $1.steps } }
    var averageStepRatio: Double {
        let totalMaxSteps = items.reduce(0) { $0 + $1.maxSteps }
        guard totalMaxSteps > 0 else { return 0 }
        return Double(totalSteps) / Double(totalMaxSteps)
    }
    var firstGuessWinsCount: Int { items.filter { $0.finalState && $0.steps == 1 }.count }
    var firstGuessWinRate: Double {
        guard wonGames > 0 else { return 0 }
        return (Double(firstGuessWinsCount) / Double(wonGames)) * 100
    }


    // MARK: - Timing Metrics

    /// Total number of games played with any active time limit.
    var timedGamesCount: Int {
        items.filter { $0.isTimed }.count
    }
    var timeoutLossesCount: Int {
        items.filter {
            $0.finalState == false &&
            ($0.endReason == .timeoutPerGuess || $0.endReason == .timeoutGame)
        }.count
    }
    var timeoutRate: Double {
        guard totalGames > 0 else { return 0 }
        return (Double(timeoutLossesCount) / Double(totalGames)) * 100
    }

    /// Total number of games played with active guess time limit.
    var perGuessTimedGamesCount: Int {
        items.filter { $0.hasPerGuessLimit }.count
    }

    /// Total number of games played with active game time limit.
    var perGameTimedGamesCount: Int {
        items.filter { $0.hasTotalTimeLimit }.count
    }

    /// Longest consecutive win streak across all game types.
    var bestWinStreak: Int {
        var current = 0
        var best = 0
        // items are stored newest-first, so reverse to evaluate streaks in chronological order.
        for item in items.reversed() {
            if item.finalState {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    /// Average completion time across all finished games.
    var averageDuration: TimeInterval {
        guard totalGames > 0 else { return 0 }
        let totalTime = items.reduce(0.0) { $0 + $1.duration }
        return totalTime / Double(items.count)
    }

    /// Average guess duration across all finished games.
    var averageStepDuration: TimeInterval {
        let stepTimes = items.flatMap(\.guessDurations)
        guard stepTimes.isEmpty == false else { return 0 }
        let allStepTimes = stepTimes.reduce(0.0) { $0 + Double($1) }
        return allStepTimes / Double(stepTimes.count)
    }


    /// Average completion time for all won games.
    var averageDurationForWonGames: TimeInterval {
        let wonItems = items.filter { $0.finalState }
        guard wonItems.isEmpty == false else { return 0 }
        let totalTime = wonItems.reduce(0.0) { $0 + $1.duration }
        return totalTime / Double(wonItems.count)
    }


    /// Average guess duration for all won games.
    var averageStepDurationForWonGames: TimeInterval {
        let wonItems = items.filter { $0.finalState }
        let stepTimes = wonItems.flatMap(\.guessDurations)
        guard stepTimes.isEmpty == false else { return 0 }
        let allStepTimes = stepTimes.reduce(0.0) { $0 + Double($1) }
        return allStepTimes / Double(stepTimes.count)
    }

    /// The absolute fastest win in seconds.
    var fastestWin: TimeInterval? {
        items.filter { $0.finalState }.map { $0.duration }.min()
    }

    // MARK: - Averages

    var averageScore: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalScore) / Double(totalGames)
    }

    var averageSteps: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalSteps) / Double(totalGames)
    }

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return (Double(wonGames) / Double(totalGames)) * 100
    }

    // MARK: - Mode Preferences

    /// Dominant mode preference derived from history.
    enum ModeResult: Equatable { case hard, normal, tie, none }
    var mostUsedMode: ModeResult {
        guard totalGames > 0 else { return .none }
        let hardCount = items.filter { $0.hardMode }.count
        let normalCount = totalGames - hardCount
        if hardCount == normalCount { return .tie }
        return hardCount > normalCount ? .hard : .normal
    }

    var mostUsedLength: Int? {
        guard totalGames > 0 else { return nil }
        var lengthCounts: [Int: Int] = [:]
        for item in items { lengthCounts[item.answer.count, default: 0] += 1 }
        return lengthCounts.max(by: { lhs, rhs in
            lhs.value == rhs.value ? rhs.key > lhs.key : rhs.value < lhs.value
        })?.key
    }

    /// Dominant repeats preference derived from history.
    enum mostUsedRepeatsResult: Equatable { case tie, on, off, none }
    var mostUsedRepeats: mostUsedRepeatsResult {
        guard totalGames > 0 else { return .none }

        let trueCount = items.filter { $0.enableRepeats }.count
        let falseCount = items.count - trueCount

        if trueCount == falseCount {
            return .tie
        } else if trueCount > falseCount {
            return .on
        } else {
            return .off
        }
    }

    /// Most frequent timer setup profile.
    enum mostUsedTimerResult: Equatable { case all, perGuess, perGame, off, none }
    var mostUsedTimers: mostUsedTimerResult {
        guard totalGames > 0 else { return .none }

        let allTimedGamesCount = items.filter { $0.hasPerGuessLimit && $0.hasTotalTimeLimit }.count
        let perGuessOnlyGamesCount = items.filter { $0.hasPerGuessLimit && $0.hasTotalTimeLimit == false }.count
        let perGameOnlyGamesCount = items.filter { $0.hasPerGuessLimit == false && $0.hasTotalTimeLimit }.count
        let relaxedGamesCount = items.filter { $0.hasPerGuessLimit == false && $0.hasTotalTimeLimit == false }.count

        let counts: [(mostUsedTimerResult, Int)] = [
            (.all, allTimedGamesCount),
            (.perGuess, perGuessOnlyGamesCount),
            (.perGame, perGameOnlyGamesCount),
            (.off, relaxedGamesCount)
        ]

        guard let winning = counts.max(by: { lhs, rhs in
            lhs.1 == rhs.1 ? false : lhs.1 < rhs.1
        }) else {
            return .none
        }

        return winning.0
    }
}
