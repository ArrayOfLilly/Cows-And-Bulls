//
//  GameDependencies.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

struct GameDependencies {
    let gameplayStore: GameplayStore
    let gameSessionStore: GameSessionStore
    let historyStore: HistoryStore
    let profileStore: ProfileStore
    let timerController: GameTimerController
    let soundEffectPlayer: any SoundEffectPlaying

    var turnRuntime: GameTurnRuntime {
        GameTurnRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            timerController: timerController
        )
    }

    var sessionFlowRuntime: GameSessionFlowRuntime {
        GameSessionFlowRuntime(
            gameplayStore: gameplayStore,
            gameSessionStore: gameSessionStore,
            historyStore: historyStore,
            profileStore: profileStore,
            timerController: timerController
        )
    }

    func playSound(_ effect: SoundPlayer.Effect, enabled: Bool, volume: Double) {
        soundEffectPlayer.play(effect, enabled: enabled, volume: volume)
    }
}
