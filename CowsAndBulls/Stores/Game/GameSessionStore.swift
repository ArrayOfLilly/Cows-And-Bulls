//
//  GameSessionStore.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation
internal import Combine

struct GameplaySettingsSnapshot: Equatable {
    let maximumGuesses: Int
    let showGuessCount: Bool
    let answerLength: Int
    let enableHardMode: Bool
    let enableRepeats: Bool
    let enablePerGuessTimeLimit: Bool
    let enableGameTimeLimit: Bool
    let perGuessTimeLimitSeconds: Int
    let gameTimeLimitSeconds: Int
}

private struct StartedTimerSettings: Equatable {
    let enablePerGuessTimeLimit: Bool
    let enableGameTimeLimit: Bool
    let perGuessTimeLimitSeconds: Int
    let gameTimeLimitSeconds: Int
}

extension ProfileSettings {
    var gameplaySettingsSnapshot: GameplaySettingsSnapshot {
        GameplaySettingsSnapshot(
            maximumGuesses: maximumGuesses,
            showGuessCount: showGuessCount,
            answerLength: answerLength,
            enableHardMode: enableHardMode,
            enableRepeats: enableRepeats,
            enablePerGuessTimeLimit: enablePerGuessTimeLimit,
            enableGameTimeLimit: enableGameTimeLimit,
            perGuessTimeLimitSeconds: perGuessTimeLimitSeconds,
            gameTimeLimitSeconds: gameTimeLimitSeconds
        )
    }

    fileprivate var startedTimerSettings: StartedTimerSettings {
        StartedTimerSettings(
            enablePerGuessTimeLimit: enablePerGuessTimeLimit,
            enableGameTimeLimit: enableGameTimeLimit,
            perGuessTimeLimitSeconds: perGuessTimeLimitSeconds,
            gameTimeLimitSeconds: gameTimeLimitSeconds
        )
    }
}

@MainActor
final class GameSessionStore: ObservableObject {
    @Published private(set) var gameInProgress = false
    @Published private(set) var hasSubmittedGuess = false
    @Published private(set) var perGuessRemainingSeconds = 0
    @Published private(set) var gameRemainingSeconds = 0
    @Published private(set) var isPaused = false

    private(set) var guessDurations: [Int] = []
    private(set) var timeoutEndReason: HistoryItem.EndReason?
    private(set) var startedSettingsSnapshot: GameplaySettingsSnapshot?

    private var gameStartTime: Date?
    private var lastGuessTime: Date?
    private var gameEndTime: Date?
    private var pauseStartedAt: Date?
    private var pausedForWindowClose = false
    private var startedTimerSettings: StartedTimerSettings?

    var canEditGameplaySettings: Bool {
        gameInProgress == false
    }

    func beginGame(with settings: ProfileSettings, at now: Date = Date()) {
        gameInProgress = true
        hasSubmittedGuess = false
        perGuessRemainingSeconds = settings.enablePerGuessTimeLimit ? settings.perGuessTimeLimitSeconds : 0
        gameRemainingSeconds = settings.enableGameTimeLimit ? settings.gameTimeLimitSeconds : 0
        isPaused = false
        guessDurations.removeAll()
        timeoutEndReason = nil
        startedSettingsSnapshot = settings.gameplaySettingsSnapshot
        startedTimerSettings = settings.startedTimerSettings
        gameStartTime = now
        lastGuessTime = now
        gameEndTime = nil
        pauseStartedAt = nil
        pausedForWindowClose = false
    }

    func recordSubmittedGuess(at now: Date = Date()) {
        guard gameInProgress else { return }
        hasSubmittedGuess = true
        let elapsed = now.timeIntervalSince(lastGuessTime ?? now)
        guessDurations.insert(Int(elapsed.rounded()), at: 0)
        lastGuessTime = now
    }

    func finishGame(at now: Date = Date()) {
        gameInProgress = false
        isPaused = false
        pauseStartedAt = nil
        pausedForWindowClose = false
        gameEndTime = now
    }

    func resetSession() {
        gameInProgress = false
        hasSubmittedGuess = false
        perGuessRemainingSeconds = 0
        gameRemainingSeconds = 0
        isPaused = false
        guessDurations.removeAll()
        timeoutEndReason = nil
        startedSettingsSnapshot = nil
        gameStartTime = nil
        lastGuessTime = nil
        gameEndTime = nil
        pauseStartedAt = nil
        pausedForWindowClose = false
        startedTimerSettings = nil
    }

    func tickPerGuessSecond() -> Bool {
        guard perGuessRemainingSeconds > 0 else { return true }
        perGuessRemainingSeconds -= 1
        return perGuessRemainingSeconds == 0
    }

    func tickGameSecond() -> Bool {
        guard gameRemainingSeconds > 0 else { return true }
        gameRemainingSeconds -= 1
        return gameRemainingSeconds == 0
    }

    func restartPerGuessTimer(seconds: Int) {
        perGuessRemainingSeconds = seconds
    }

    func pause(at now: Date = Date(), dueToWindowClose: Bool = false) {
        guard isPaused == false else { return }
        pauseStartedAt = now
        isPaused = true
        if dueToWindowClose {
            pausedForWindowClose = true
        }
    }

    func resume(at now: Date = Date()) {
        guard isPaused else { return }
        if let pauseStartedAt {
            let pauseDuration = now.timeIntervalSince(pauseStartedAt)
            gameStartTime = gameStartTime?.addingTimeInterval(pauseDuration)
            lastGuessTime = lastGuessTime?.addingTimeInterval(pauseDuration)
        }
        pauseStartedAt = nil
        isPaused = false
        pausedForWindowClose = false
    }

    func resumeAfterWindowCloseIfNeeded(at now: Date = Date()) -> Bool {
        guard pausedForWindowClose, isPaused else { return false }
        resume(at: now)
        return true
    }

    func markTimeout(_ reason: HistoryItem.EndReason, at now: Date = Date()) {
        finishGame(at: now)
        timeoutEndReason = reason
    }

    func markSurrender(at now: Date = Date()) {
        finishGame(at: now)
        timeoutEndReason = .surrender
    }

    func makeHistoryItem(
        finalState: Bool,
        answer: String,
        guesses: [String],
        score: Int,
        currentSettings: ProfileSettings,
        endReason: HistoryItem.EndReason = .completed,
        now: Date = Date()
    ) -> HistoryItem? {
        guard guesses.isEmpty == false else { return nil }
        guard let gameStartTime else { return nil }

        let effectiveSettings = startedSettingsSnapshot ?? currentSettings.gameplaySettingsSnapshot
        let effectiveTimers = startedTimerSettings ?? currentSettings.startedTimerSettings
        let totalDuration = max(0, (gameEndTime ?? now).timeIntervalSince(gameStartTime))

        return HistoryItem(
            duration: totalDuration,
            hasPerGuessLimit: effectiveTimers.enablePerGuessTimeLimit,
            hasTotalTimeLimit: effectiveTimers.enableGameTimeLimit,
            perGuessLimit: effectiveTimers.perGuessTimeLimitSeconds,
            totalTimeLimit: effectiveTimers.gameTimeLimitSeconds,
            guessDurations: guessDurations,
            finalState: finalState,
            answer: answer,
            steps: guesses.count,
            score: score,
            maxSteps: effectiveSettings.maximumGuesses,
            hardMode: effectiveSettings.enableHardMode,
            enableRepeats: effectiveSettings.enableRepeats,
            guesses: guesses,
            guessResults: guesses.map { GameLogic.encodedResult(guess: $0, answer: answer) },
            endReason: endReason
        )
    }
}
