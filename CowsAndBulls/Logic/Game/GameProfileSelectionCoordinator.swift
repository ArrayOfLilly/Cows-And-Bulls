//
//  GameProfileSelectionCoordinator.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import Foundation

@MainActor
enum GameProfileSelectionCoordinator {
    static func handleSelection(
        _ newValue: String,
        decision: ProfileSelectionDecision,
        profileStore: ProfileStore,
        lastSelectedProfileId: String,
        sessionFlowRuntime: GameSessionFlowRuntime,
        setShowNewProfileSheet: (Bool) -> Void,
        setPendingProfileSwitchId: (String?) -> Void,
        setShowProfileSwitchDialog: (Bool) -> Void,
        setLastSelectedProfileId: (String) -> Void,
        hideVictoryCelebration: () -> Void
    ) {
        _ = newValue
        switch decision {
        case .showNewProfileSheet:
            setShowNewProfileSheet(true)
            profileStore.selectProfile(id: lastSelectedProfileId)
        case let .confirmInProgressSwitch(profileId):
            setPendingProfileSwitchId(profileId)
            setShowProfileSwitchDialog(true)
            profileStore.selectProfile(id: lastSelectedProfileId)
        case let .switchDirectly(profileId):
            GameSessionFlowCoordinator.applyProfileSwitch(
                to: profileId,
                runtime: sessionFlowRuntime,
                setLastSelectedProfileId: setLastSelectedProfileId,
                hideVictoryCelebration: hideVictoryCelebration
            )
        }
    }

    static func createProfile(
        named name: String,
        profileStore: ProfileStore,
        clearName: () -> Void,
        dismissSheet: () -> Void
    ) {
        profileStore.createProfile(named: name)
        clearName()
        dismissSheet()
    }

    static func cancelProfileCreation(
        clearName: () -> Void,
        dismissSheet: () -> Void
    ) {
        clearName()
        dismissSheet()
    }
}
