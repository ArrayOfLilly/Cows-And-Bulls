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

    @Test("Game mode message and profile picker help text are derived outside the view")
    func gameModeMessageAndProfilePickerHelpText() {
        var settings = ProfileSettings.default
        settings.answerLength = 5
        settings.enableHardMode = true
        settings.enableRepeats = true

        let rules = GamePresentationRules(
            settings: settings,
            startedSettingsSnapshot: nil,
            guessesCount: 0,
            gameInProgress: true,
            hasGuesses: false,
            isWon: false,
            isGameOver: false
        )

        let expectedMessage =
            localized("game.mode.title") + " " +
            String(localized: "game.mode.hard") + " " +
            String(localized: "game.mode.format") + " 5 " +
            String(localized: "game.mode.repeats")

        #expect(rules.gameModeMessage == expectedMessage)
        #expect(rules.profilePickerHelpText == localized("profile.switch.disabled.in_progress"))
    }

    @Test("Profile selection decision is derived outside the view")
    @MainActor
    func profileSelectionDecision() {
        let idleRules = GamePresentationRules(
            settings: .default,
            startedSettingsSnapshot: nil,
            guessesCount: 0,
            gameInProgress: false,
            hasGuesses: false,
            isWon: false,
            isGameOver: false
        )

        let activeRules = GamePresentationRules(
            settings: .default,
            startedSettingsSnapshot: nil,
            guessesCount: 2,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: false
        )

        #expect(idleRules.decisionForProfileSelection(ProfileStore.newProfileSelectionId, newProfileSelectionId: ProfileStore.newProfileSelectionId) == .showNewProfileSheet)
        #expect(idleRules.decisionForProfileSelection("profile-b", newProfileSelectionId: ProfileStore.newProfileSelectionId) == .switchDirectly(profileId: "profile-b"))
        #expect(activeRules.decisionForProfileSelection("profile-c", newProfileSelectionId: ProfileStore.newProfileSelectionId) == .confirmInProgressSwitch(profileId: "profile-c"))
    }

    @Test("Pause and window-close guards are derived outside the view")
    func pauseAndWindowCloseGuards() {
        var timedSettings = ProfileSettings.default
        timedSettings.enablePerGuessTimeLimit = true
        timedSettings.perGuessTimeLimitSeconds = 15

        let activeRules = GamePresentationRules(
            settings: timedSettings,
            startedSettingsSnapshot: nil,
            guessesCount: 2,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: false
        )

        let wonRules = GamePresentationRules(
            settings: timedSettings,
            startedSettingsSnapshot: nil,
            guessesCount: 2,
            gameInProgress: true,
            hasGuesses: true,
            isWon: true,
            isGameOver: false
        )

        let noGuessRules = GamePresentationRules(
            settings: timedSettings,
            startedSettingsSnapshot: nil,
            guessesCount: 0,
            gameInProgress: true,
            hasGuesses: false,
            isWon: false,
            isGameOver: false
        )

        #expect(activeRules.canTogglePause)
        #expect(activeRules.canPauseForWindowClose)
        #expect(activeRules.shouldPromptOnClose)

        #expect(wonRules.canTogglePause == false)
        #expect(wonRules.canPauseForWindowClose == false)
        #expect(wonRules.shouldPromptOnClose == false)

        #expect(noGuessRules.canTogglePause)
        #expect(noGuessRules.canPauseForWindowClose)
        #expect(noGuessRules.shouldPromptOnClose == false)
    }

    @Test("Timeout, surrender, and loss alert texts are derived outside the view")
    func timeoutSurrenderAndLossMessages() {
        let rules = GamePresentationRules(
            settings: .default,
            startedSettingsSnapshot: nil,
            guessesCount: 2,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: false
        )

        #expect(
            rules.timeoutGameOverMessage(for: .perGuess, answer: "1234")
            == localized("alert.per_guess_timeout.message", "1234")
        )
        #expect(
            rules.timeoutGameOverMessage(for: .game, answer: "1234")
            == localized("alert.game_timeout.message", "1234")
        )
        #expect(
            rules.surrenderGameOverMessage(answer: "1234")
            == localized("alert.surrender.message", "1234")
        )
        #expect(
            rules.lossAlertMessage(answer: "1234", gameOverMessage: "")
            == localized("alert.lose.message", "1234")
        )
        #expect(
            rules.lossAlertMessage(answer: "1234", gameOverMessage: "Custom loss")
            == "Custom loss"
        )
    }

    @Test("Loss end reason defaults to completed when no timeout was recorded")
    func lossEndReasonFallback() {
        let rules = GamePresentationRules(
            settings: .default,
            startedSettingsSnapshot: nil,
            guessesCount: 2,
            gameInProgress: true,
            hasGuesses: true,
            isWon: false,
            isGameOver: true
        )

        #expect(rules.lossEndReason(timeoutEndReason: nil) == .completed)
        #expect(rules.lossEndReason(timeoutEndReason: .timeoutGame) == .timeoutGame)
    }
}
