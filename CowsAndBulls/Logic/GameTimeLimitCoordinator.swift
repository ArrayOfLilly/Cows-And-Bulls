//
//  GameTimeLimitCoordinator.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import Foundation

enum GameTimeLimitType {
    case perGuess
    case game
}

@MainActor
enum GameTimeLimitCoordinator {
    static func start(
        timerController: GameTimerController,
        gameSessionStore: GameSessionStore,
        perGuessActive: Bool,
        gameActive: Bool,
        onExpire: @escaping @MainActor (GameTimeLimitType) -> Void
    ) {
        timerController.startTimers(
            perGuessActive: perGuessActive,
            gameActive: gameActive,
            onPerGuessTick: perGuessTickHandler(gameSessionStore: gameSessionStore, onExpire: onExpire),
            onGameTick: gameTickHandler(gameSessionStore: gameSessionStore, onExpire: onExpire)
        )
    }

    static func restartPerGuess(
        timerController: GameTimerController,
        gameSessionStore: GameSessionStore,
        isActive: Bool,
        seconds: Int,
        onExpire: @escaping @MainActor (GameTimeLimitType) -> Void
    ) {
        gameSessionStore.restartPerGuessTimer(seconds: seconds)
        timerController.restartPerGuessTimerIfNeeded(
            isActive: isActive,
            onPerGuessTick: perGuessTickHandler(gameSessionStore: gameSessionStore, onExpire: onExpire)
        )
    }

    static func perGuessTickHandler(
        gameSessionStore: GameSessionStore,
        onExpire: @escaping @MainActor (GameTimeLimitType) -> Void
    ) -> @MainActor () -> Void {
        {
            if gameSessionStore.tickPerGuessSecond() {
                onExpire(.perGuess)
            }
        }
    }

    static func gameTickHandler(
        gameSessionStore: GameSessionStore,
        onExpire: @escaping @MainActor (GameTimeLimitType) -> Void
    ) -> @MainActor () -> Void {
        {
            if gameSessionStore.tickGameSecond() {
                onExpire(.game)
            }
        }
    }
}
