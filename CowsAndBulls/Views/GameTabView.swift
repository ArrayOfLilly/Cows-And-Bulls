//
//  GameTabView.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct GameTabView: View {
    let context: GameTabContext
    @Binding var showSurrenderConfirmation: Bool
    @Binding var pendingProfileSwitchId: String?
    @Binding var showProfileSwitchDialog: Bool
    let showWinAlert: Binding<Bool>
    let isGameOver: Binding<Bool>
    let focusBinding: FocusState<Bool>.Binding
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

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                GameHeaderSection(context: context.header, onTogglePause: onTogglePause)
                GameInputSection(
                    context: context.input,
                    onSubmitGuess: onSubmitGuess,
                    focusBinding: focusBinding
                )
            }
            .frame(maxWidth: .infinity)
            .background(headerBackground)

            GuessesListSection(context: context.guessesList)

            GameFooterSection(
                context: context.footer,
                onSurrender: { showSurrenderConfirmation = true },
                onRestart: onRestart
            )
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .onChange(of: context.guess, onGuessChange)
        .confirmationDialog(localized("game.surrender.title"), isPresented: $showSurrenderConfirmation, titleVisibility: .visible) {
            Button(localized("game.surrender.action"), role: .destructive) {
                onSurrender()
            }
            Button(localized("common.action.cancel"), role: .cancel) { }
        } message: {
            Text(localized("game.surrender.message"))
        }
        .confirmationDialog(localized("profile.switch.confirm.title"), isPresented: $showProfileSwitchDialog, titleVisibility: .visible) {
            Button(localized("profile.switch.confirm.surrender"), role: .destructive) {
                onConfirmProfileSwitchSurrender()
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchSurrender")
            Button(localized("profile.switch.confirm.pause")) {
                onConfirmProfileSwitchPause()
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchPause")
            Button(localized("common.action.cancel"), role: .cancel) {
                pendingProfileSwitchId = nil
            }
            .accessibilityIdentifier("profileSwitchCancel")
        } message: {
            Text(localized("profile.switch.confirm.message"))
        }
        .alert(localized("game.alert.win.title"), isPresented: showWinAlert) {
            Button(localized("common.action.play_again")) {
                onWinPlayAgain()
            }
            Button(localized("common.action.ok")) {
                onWinAcknowledge()
            }
        } message: {
            Text(localized("alert.win.message", context.guessesCount, context.scoreValue))
        }
        .alert(localized("game.alert.lose.title"), isPresented: isGameOver) {
            Button(localized("common.action.play_again")) {
                onLossPlayAgain()
            }
            Button(localized("common.action.ok")) {
                onLossAcknowledge()
            }
        } message: {
            Text(context.lossAlertMessage)
        }
        .tabItem {
            Label(localized("tab.game"), systemImage: "gamecontroller")
        }
    }

    private var headerBackground: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .opacity(0.05)
            .allowsHitTesting(false)
            .clipped()
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
