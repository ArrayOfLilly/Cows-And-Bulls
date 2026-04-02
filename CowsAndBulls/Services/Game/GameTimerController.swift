//
//  GameTimerController.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

@MainActor
final class GameTimerController {
    private var perGuessTask: Task<Void, Never>?
    private var gameTask: Task<Void, Never>?

    deinit {
        perGuessTask?.cancel()
        gameTask?.cancel()
    }

    func stopAll() {
        perGuessTask?.cancel()
        perGuessTask = nil
        gameTask?.cancel()
        gameTask = nil
    }

    func startTimers(
        perGuessActive: Bool,
        gameActive: Bool,
        onPerGuessTick: @escaping @MainActor () -> Void,
        onGameTick: @escaping @MainActor () -> Void
    ) {
        if perGuessActive {
            startPerGuessTimer(onTick: onPerGuessTick)
        }
        if gameActive {
            startGameTimer(onTick: onGameTick)
        }
    }

    func restartPerGuessTimerIfNeeded(
        isActive: Bool,
        onPerGuessTick: @escaping @MainActor () -> Void
    ) {
        guard isActive else { return }
        startPerGuessTimer(onTick: onPerGuessTick)
    }

    private func startPerGuessTimer(onTick: @escaping @MainActor () -> Void) {
        perGuessTask?.cancel()
        perGuessTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                onTick()
            }
        }
    }

    private func startGameTimer(onTick: @escaping @MainActor () -> Void) {
        gameTask?.cancel()
        gameTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                onTick()
            }
        }
    }
}
