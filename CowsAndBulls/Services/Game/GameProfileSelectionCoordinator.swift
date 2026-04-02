//
//  GameProfileSelectionCoordinator.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import Foundation

struct GameProfileSelectionCallbacks {
    let setShowNewProfileSheet: (Bool) -> Void
    let setPendingProfileSwitchId: (String?) -> Void
    let setShowProfileSwitchDialog: (Bool) -> Void
    let directSwitchCallbacks: GameProfileSwitchCallbacks
}

struct GameProfileCreationCallbacks {
    let clearName: () -> Void
    let dismissSheet: () -> Void
}

@MainActor
enum GameProfileSelectionCoordinator {
    static func handleSelection(
        _ newValue: String,
        decision: ProfileSelectionDecision,
        profileStore: ProfileStore,
        lastSelectedProfileId: String,
        sessionFlowRuntime: GameSessionFlowRuntime,
        callbacks: GameProfileSelectionCallbacks
    ) {
        _ = newValue
        switch decision {
        case .showNewProfileSheet:
            callbacks.setShowNewProfileSheet(true)
            profileStore.selectProfile(id: lastSelectedProfileId)
        case let .confirmInProgressSwitch(profileId):
            callbacks.setPendingProfileSwitchId(profileId)
            callbacks.setShowProfileSwitchDialog(true)
            profileStore.selectProfile(id: lastSelectedProfileId)
        case let .switchDirectly(profileId):
            GameSessionFlowCoordinator.applyProfileSwitch(
                to: profileId,
                runtime: sessionFlowRuntime,
                callbacks: callbacks.directSwitchCallbacks
            )
        }
    }

    static func createProfile(
        named name: String,
        profileStore: ProfileStore,
        callbacks: GameProfileCreationCallbacks
    ) {
        profileStore.createProfile(named: name)
        callbacks.clearName()
        callbacks.dismissSheet()
    }

    static func cancelProfileCreation(
        callbacks: GameProfileCreationCallbacks
    ) {
        callbacks.clearName()
        callbacks.dismissSheet()
    }
}
