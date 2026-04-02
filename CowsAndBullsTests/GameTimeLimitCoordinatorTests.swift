//
//  GameTimeLimitCoordinatorTests.swift
//  CowsAndBullsTests
//
//  Created by OpenAI Codex.
//

import Testing
@testable import Cows___Bulls

@MainActor
struct GameTimeLimitCoordinatorTests {
    @Test("Per-guess tick handler expires only when the countdown reaches zero")
    func perGuessTickHandlerExpiresAtZero() {
        let sessionStore = GameSessionStore()
        var settings = ProfileSettings.default
        settings.enablePerGuessTimeLimit = true
        settings.perGuessTimeLimitSeconds = 2
        sessionStore.beginGame(with: settings)

        var expiredTypes: [GameTimeLimitType] = []
        let handler = GameTimeLimitCoordinator.perGuessTickHandler(gameSessionStore: sessionStore) {
            expiredTypes.append($0)
        }

        handler()
        #expect(sessionStore.perGuessRemainingSeconds == 1)
        #expect(expiredTypes.isEmpty)

        handler()
        #expect(sessionStore.perGuessRemainingSeconds == 0)
        #expect(expiredTypes == [.perGuess])
    }

    @Test("Game tick handler expires only when the countdown reaches zero")
    func gameTickHandlerExpiresAtZero() {
        let sessionStore = GameSessionStore()
        var settings = ProfileSettings.default
        settings.enableGameTimeLimit = true
        settings.gameTimeLimitSeconds = 2
        sessionStore.beginGame(with: settings)

        var expiredTypes: [GameTimeLimitType] = []
        let handler = GameTimeLimitCoordinator.gameTickHandler(gameSessionStore: sessionStore) {
            expiredTypes.append($0)
        }

        handler()
        #expect(sessionStore.gameRemainingSeconds == 1)
        #expect(expiredTypes.isEmpty)

        handler()
        #expect(sessionStore.gameRemainingSeconds == 0)
        #expect(expiredTypes == [.game])
    }
}
