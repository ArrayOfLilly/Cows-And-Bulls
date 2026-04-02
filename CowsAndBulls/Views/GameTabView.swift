//
//  GameTabView.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct GameTabView: View {
    let context: GameTabContext
    let actions: GameTabActions
    @Binding var showSurrenderConfirmation: Bool
    @Binding var pendingProfileSwitchId: String?
    @Binding var showProfileSwitchDialog: Bool
    let showWinAlert: Binding<Bool>
    let isGameOver: Binding<Bool>
    let focusBinding: FocusState<Bool>.Binding

    var body: some View {
        GameTabContentView(
            context: context,
            focusBinding: focusBinding,
            onTogglePause: actions.onTogglePause,
            onSubmitGuess: actions.onSubmitGuess,
            onShowSurrenderConfirmation: { showSurrenderConfirmation = true },
            onRestart: actions.onRestart
        )
        .onAppear(perform: actions.onAppear)
        .onDisappear(perform: actions.onDisappear)
        .onChange(of: context.guess, actions.onGuessChange)
        .modifier(
            GameTabPresentationModifier(
                context: context,
                showSurrenderConfirmation: $showSurrenderConfirmation,
                pendingProfileSwitchId: $pendingProfileSwitchId,
                showProfileSwitchDialog: $showProfileSwitchDialog,
                showWinAlert: showWinAlert,
                isGameOver: isGameOver,
                onSurrender: actions.onSurrender,
                onConfirmProfileSwitchSurrender: actions.onConfirmProfileSwitchSurrender,
                onConfirmProfileSwitchPause: actions.onConfirmProfileSwitchPause,
                onWinPlayAgain: actions.onWinPlayAgain,
                onWinAcknowledge: actions.onWinAcknowledge,
                onLossPlayAgain: actions.onLossPlayAgain,
                onLossAcknowledge: actions.onLossAcknowledge
            )
        )
        .tabItem {
            Label(localized("tab.game"), systemImage: "gamecontroller")
        }
    }
}

struct GameTabContext {
    let header: GameHeaderContext
    let input: GameInputContext
    let guessesList: GuessesListContext
    let footer: GameFooterContext
    let guess: String
    let guessesCount: Int
    let scoreValue: Int
    let lossAlertMessage: String
}

struct GameTabActions {
    let onAppear: () -> Void
    let onDisappear: () -> Void
    let onGuessChange: () -> Void
    let onTogglePause: () -> Void
    let onSubmitGuess: () -> Void
    let onSurrender: () -> Void
    let onConfirmProfileSwitchSurrender: () -> Void
    let onConfirmProfileSwitchPause: () -> Void
    let onWinPlayAgain: () -> Void
    let onWinAcknowledge: () -> Void
    let onLossPlayAgain: () -> Void
    let onLossAcknowledge: () -> Void
    let onRestart: () -> Void
}
