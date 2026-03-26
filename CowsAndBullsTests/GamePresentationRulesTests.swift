//
//  GamePresentationRulesTests.swift
//  CowsAndBullsTests
//
//  Created by Codex on 2026. 03. 18..
//

import Testing
import Foundation
@testable import Cows___Bulls

struct GamePresentationRulesTests {
    @Test("Score fairness uses the lower of current and started timer configurations")
    func scoreUsesLowerOfStartedAndCurrentTimerConfigurations() {
        var settings = ProfileSettings.default
        settings.answerLength = 6
        settings.maximumGuesses = 8
        settings.showGuessCount = false
        settings.enableHardMode = true
        settings.enablePerGuessTimeLimit = true
        settings.perGuessTimeLimitSeconds = 10
        settings.enableGameTimeLimit = true
        settings.gameTimeLimitSeconds = 120

        let startedSnapshot = GameplaySettingsSnapshot(
            maximumGuesses: 8,
            showGuessCount: false,
            answerLength: 6,
            enableHardMode: true,
            enableRepeats: false,
            enablePerGuessTimeLimit: false,
            enableGameTimeLimit: false,
            perGuessTimeLimitSeconds: 0,
            gameTimeLimitSeconds: 0
        )

        let rules = GamePresentationRules(
            settings: settings,
            startedSettingsSnapshot: startedSnapshot,
            guessesCount: 3,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: false
        )

        let currentScore = GameLogic.score(
            codeLength: settings.answerLength,
            allowRepeats: settings.enableRepeats,
            hardMode: settings.enableHardMode,
            hidesRemainingGuesses: settings.showGuessCount == false,
            maxGuesses: settings.maximumGuesses,
            usedGuesses: 3,
            perMoveTimeLimit: 10,
            totalTimeLimit: 120
        )

        let startedScore = GameLogic.score(
            codeLength: startedSnapshot.answerLength,
            allowRepeats: startedSnapshot.enableRepeats,
            hardMode: startedSnapshot.enableHardMode,
            hidesRemainingGuesses: startedSnapshot.showGuessCount == false,
            maxGuesses: startedSnapshot.maximumGuesses,
            usedGuesses: 3,
            perMoveTimeLimit: 0,
            totalTimeLimit: 0
        )

        #expect(rules.scoreValue == min(currentScore, startedScore))
    }

    @Test("Timer activity and surrender availability are derived outside the view")
    func timerFlagsAndSurrenderAvailability() {
        var settings = ProfileSettings.default
        settings.enablePerGuessTimeLimit = true
        settings.perGuessTimeLimitSeconds = 20
        settings.enableGameTimeLimit = false

        let rules = GamePresentationRules(
            settings: settings,
            startedSettingsSnapshot: nil,
            guessesCount: 1,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: false
        )

        #expect(rules.isPerGuessLimitActive)
        #expect(rules.isGameLimitActive == false)
        #expect(rules.isAnyTimerActive)
        #expect(rules.canChangeProfile == false)
        #expect(rules.canSurrender)
    }
}
