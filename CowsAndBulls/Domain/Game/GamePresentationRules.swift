//
//  GamePresentationRules.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

enum ProfileSelectionDecision: Equatable {
    case showNewProfileSheet
    case confirmInProgressSwitch(profileId: String)
    case switchDirectly(profileId: String)
}

enum TimeLimitPresentation: Equatable {
    case perGuess
    case game
}

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

    var canTogglePause: Bool {
        isAnyTimerActive && isWon == false && isGameOver == false
    }

    var canPauseForWindowClose: Bool {
        isWon == false && isGameOver == false
    }

    var shouldPromptOnClose: Bool {
        gameInProgress && hasGuesses && isWon == false && isGameOver == false
    }

    var profilePickerHelpText: String {
        gameInProgress ? localized("profile.switch.disabled.in_progress") : ""
    }

    var gameModeMessage: String {
        var message = localized("game.mode.title") + " "
        message += enableHardMode ? String(localized: "game.mode.hard") : String(localized: "game.mode.normal")
        message += " " + String(localized: "game.mode.format") + " " + String(settings.answerLength) + " "
        message += settings.enableRepeats ? String(localized: "game.mode.repeats") : String(localized: "game.mode.unique")
        return message
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

    func decisionForProfileSelection(
        _ profileId: String,
        newProfileSelectionId: String
    ) -> ProfileSelectionDecision {
        if profileId == newProfileSelectionId {
            return .showNewProfileSheet
        }
        if canChangeProfile == false {
            return .confirmInProgressSwitch(profileId: profileId)
        }
        return .switchDirectly(profileId: profileId)
    }

    func timeoutGameOverMessage(for type: TimeLimitPresentation, answer: String) -> String {
        switch type {
        case .perGuess:
            return localized("alert.per_guess_timeout.message", answer)
        case .game:
            return localized("alert.game_timeout.message", answer)
        }
    }

    func surrenderGameOverMessage(answer: String) -> String {
        localized("alert.surrender.message", answer)
    }

    func lossAlertMessage(answer: String, gameOverMessage: String) -> String {
        gameOverMessage.isEmpty ? localized("alert.lose.message", answer) : gameOverMessage
    }

    func lossEndReason(timeoutEndReason: HistoryItem.EndReason?) -> HistoryItem.EndReason {
        timeoutEndReason ?? .completed
    }

    private var enableHardMode: Bool {
        settings.enableHardMode
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
