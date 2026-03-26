//
//  GamePresentationRules.swift
//  CowsAndBulls
//
//  Created by Codex on 2026. 03. 18..
//

import Foundation

struct GamePresentationRules: Equatable {
    let settings: ProfileSettings
    let startedSettingsSnapshot: GameplaySettingsSnapshot?
    let guessesCount: Int
    let gameInProgress: Bool
    let hasGuesses: Bool
    let isWon: Bool
    let isGameOver: Bool

    var isPerGuessLimitActive: Bool {
        settings.enablePerGuessTimeLimit && settings.perGuessTimeLimitSeconds > 0
    }

    var isGameLimitActive: Bool {
        settings.enableGameTimeLimit && settings.gameTimeLimitSeconds > 0
    }

    var isAnyTimerActive: Bool {
        isPerGuessLimitActive || isGameLimitActive
    }

    var canChangeProfile: Bool {
        gameInProgress == false
    }

    var canSurrender: Bool {
        gameInProgress && hasGuesses && isWon == false && isGameOver == false
    }

    var scoreValue: Int {
        let startedSnapshot = startedSettingsSnapshot ?? settings.gameplaySettingsSnapshot
        let currentScore = score(
            answerLength: settings.answerLength,
            enableRepeats: settings.enableRepeats,
            enableHardMode: settings.enableHardMode,
            showGuessCount: settings.showGuessCount,
            maximumGuesses: settings.maximumGuesses,
            enablePerGuessTimeLimit: settings.enablePerGuessTimeLimit,
            perGuessTimeLimitSeconds: settings.perGuessTimeLimitSeconds,
            enableGameTimeLimit: settings.enableGameTimeLimit,
            gameTimeLimitSeconds: settings.gameTimeLimitSeconds
        )
        let startedScore = score(
            answerLength: startedSnapshot.answerLength,
            enableRepeats: startedSnapshot.enableRepeats,
            enableHardMode: startedSnapshot.enableHardMode,
            showGuessCount: startedSnapshot.showGuessCount,
            maximumGuesses: startedSnapshot.maximumGuesses,
            enablePerGuessTimeLimit: startedSnapshot.enablePerGuessTimeLimit,
            perGuessTimeLimitSeconds: startedSnapshot.perGuessTimeLimitSeconds,
            enableGameTimeLimit: startedSnapshot.enableGameTimeLimit,
            gameTimeLimitSeconds: startedSnapshot.gameTimeLimitSeconds
        )
        return min(currentScore, startedScore)
    }

    private func score(
        answerLength: Int,
        enableRepeats: Bool,
        enableHardMode: Bool,
        showGuessCount: Bool,
        maximumGuesses: Int,
        enablePerGuessTimeLimit: Bool,
        perGuessTimeLimitSeconds: Int,
        enableGameTimeLimit: Bool,
        gameTimeLimitSeconds: Int
    ) -> Int {
        let perMoveLimit = (enablePerGuessTimeLimit && perGuessTimeLimitSeconds > 0) ? TimeInterval(perGuessTimeLimitSeconds) : 0
        let totalLimit = (enableGameTimeLimit && gameTimeLimitSeconds > 0) ? TimeInterval(gameTimeLimitSeconds) : 0

        return GameLogic.score(
            codeLength: answerLength,
            allowRepeats: enableRepeats,
            hardMode: enableHardMode,
            hidesRemainingGuesses: showGuessCount == false,
            maxGuesses: maximumGuesses,
            usedGuesses: guessesCount,
            perMoveTimeLimit: perMoveLimit,
            totalTimeLimit: totalLimit
        )
    }
}
