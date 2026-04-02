//
//  GameScreenSections.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct GameHeaderSection: View {
    let context: GameHeaderContext
    let onTogglePause: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ProfilePickerRow(
                profiles: context.profiles,
                selection: context.profileSelection,
                canChangeProfile: context.canChangeProfile,
                helpText: context.profilePickerHelpText
            )

            Text(context.gameModeMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                Text(localized("game.header.avg_steps", context.averageSteps))
                    .padding(.trailing, 10)
                Text(localized("game.header.best_streak", context.bestWinStreak))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            HStack(spacing: 2) {
                Text(localized("settings.theme.label"))
                Image(context.selectedBullAssetName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .animalIconStyle()
                Image(context.selectedCowAssetName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .animalIconStyle()
            }
            .padding(.bottom, 4)

            if context.isAnyTimerActive {
                TimerStatusBar(
                    isPerGuessLimitActive: context.isPerGuessLimitActive,
                    isGameLimitActive: context.isGameLimitActive,
                    perGuessRemainingSeconds: context.perGuessRemainingSeconds,
                    gameRemainingSeconds: context.gameRemainingSeconds,
                    isPaused: context.isPaused,
                    onTogglePause: onTogglePause
                )
            }
        }
        .padding(.top, 12)
    }
}

struct ProfilePickerRow: View {
    let profiles: [PlayerProfile]
    let selection: Binding<String>
    let canChangeProfile: Bool
    let helpText: String

    var body: some View {
        HStack(spacing: 8) {
            Text(localized("profile.label"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker(localized("profile.label"), selection: selection) {
                ForEach(profiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
                Divider()
                Text(localized("profile.new.picker")).tag(ProfileStore.newProfileSelectionId)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .disabled(canChangeProfile == false)
            .help(helpText)
            .accessibilityIdentifier("profilePicker")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profilePickerRow")
    }
}

struct TimerStatusBar: View {
    let isPerGuessLimitActive: Bool
    let isGameLimitActive: Bool
    let perGuessRemainingSeconds: Int
    let gameRemainingSeconds: Int
    let isPaused: Bool
    let onTogglePause: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isPerGuessLimitActive {
                Label(GameLogic.formatTime(perGuessRemainingSeconds), systemImage: "timer")
            }
            if isGameLimitActive {
                Label(GameLogic.formatTime(gameRemainingSeconds), systemImage: "hourglass")
            }
            Button(isPaused ? localized("game.timer.resume") : localized("game.timer.pause")) {
                onTogglePause()
            }
        }
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(.orange)
        .accessibilityIdentifier("timerStatusBar")
    }
}

struct GameInputSection: View {
    let context: GameInputContext
    let onSubmitGuess: () -> Void
    let focusBinding: FocusState<Bool>.Binding

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                TextField(localized("game.input.placeholder"), text: context.guessBinding)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .focused(focusBinding)
                    .onSubmit(onSubmitGuess)
                    .textFieldStyle(.roundedBorder)
                    .disabled(context.isPaused)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("guessInputField")

                Button(localized("game.input.submit"), action: onSubmitGuess)
                    .padding(4)
                    .disabled(context.isDisabledSubmitButton || context.isPaused)
                    .accessibilityIdentifier("submitGuessButton")
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 360)

            Text(context.guessInputErrorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(minHeight: 14, alignment: .top)
                .accessibilityHidden(context.guessInputErrorMessage.isEmpty)
                .accessibilityValue(context.guessInputErrorMessage)
                .accessibilityIdentifier("guessInputError")
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

struct GuessesListSection: View {
    let context: GuessesListContext

    private var guessesAccessibilityValue: String {
        context.guesses.joined(separator: "|")
    }

    var body: some View {
        List(0..<context.guesses.count, id: \.self) { index in
            let attempt = context.guesses[index]
            let duration = index < context.guessDurations.count ? context.guessDurations[index] : 0
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedGuessDisplay(attempt))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .kerning(1)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: guessDisplayWidth, alignment: .leading)
                    Text(GameLogic.formatDuration(TimeInterval(duration)))
                        .font(.system(size: 9))
                        .listStyle(.sidebar)
                }
                Spacer()
                GuessResultIconsView(
                    guess: attempt,
                    answer: context.answer,
                    bullAssetName: context.selectedBullAssetName,
                    cowAssetName: context.selectedCowAssetName
                )
            }
        }
        .listStyle(.sidebar)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("guessesList")
        .accessibilityValue(guessesAccessibilityValue)
    }

    private var guessDisplayWidth: CGFloat { 72 }

    private func formattedGuessDisplay(_ guess: String) -> String {
        guard guess.count > 4 else { return guess }
        let splitIndex = guess.index(guess.startIndex, offsetBy: 4)
        return String(guess[..<splitIndex]) + "\n" + String(guess[splitIndex...])
    }
}

struct GuessResultIconsView: View {
    let guess: String
    let answer: String
    let bullAssetName: String
    let cowAssetName: String

    var body: some View {
        let counts = GameLogic.bullCowCounts(guess: guess, answer: answer)
        let iconNames = Array(repeating: bullAssetName, count: counts.bulls)
            + Array(repeating: cowAssetName, count: counts.cows)

        if iconNames.isEmpty {
            Text("0").foregroundStyle(.secondary)
        } else if guess.count > 4 {
            VStack(alignment: .trailing, spacing: 4) {
                iconRow(iconNames.prefix(4))
                iconRow(iconNames.dropFirst(4))
            }
        } else {
            iconRow(iconNames[...])
        }
    }

    private func iconRow(_ icons: ArraySlice<String>) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(icons.enumerated()), id: \.offset) { _, name in
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .animalIconStyle()
            }
        }
    }
}

struct GameFooterSection: View {
    let context: GameFooterContext
    let onSurrender: () -> Void
    let onRestart: () -> Void

    var body: some View {
        VStack {
            if context.showGuessCount {
                Text(localized("Guesses: %lld/%lld", context.guessesCount, context.maximumGuesses))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }

            Text(String(context.guessesCount))
                .font(.caption2)
                .foregroundStyle(.clear)
                .frame(height: 0)
                .clipped()
                .accessibilityIdentifier("gameGuessCountState")
                .accessibilityValue(String(context.guessesCount))

            HStack(spacing: 12) {
                Button(localized("game.action.surrender")) {
                    onSurrender()
                }
                .foregroundStyle(Color(red: 1.0, green: 0.27, blue: 0.0))
                .disabled(context.canSurrender == false)

                Button(localized("game.action.restart"), action: onRestart)
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 20)
        }
    }
}

struct NewProfileSheet: View {
    @Binding var name: String
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized("profile.new.title"))
                .font(.headline)

            TextField(localized("profile.new.placeholder"), text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
                .accessibilityIdentifier("newProfileNameField")

            HStack {
                Spacer()
                Button(localized("common.action.cancel"), role: .cancel, action: onCancel)
                    .accessibilityIdentifier("newProfileCancel")
                Button(localized("profile.new.action")) {
                    onCreate(name)
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("newProfileCreate")
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            isNameFocused = true
        }
    }
}

struct GameHeaderContext {
    let profiles: [PlayerProfile]
    let profileSelection: Binding<String>
    let canChangeProfile: Bool
    let profilePickerHelpText: String
    let gameModeMessage: String
    let averageSteps: Double
    let bestWinStreak: Int
    let selectedBullAssetName: String
    let selectedCowAssetName: String
    let isAnyTimerActive: Bool
    let isPerGuessLimitActive: Bool
    let isGameLimitActive: Bool
    let perGuessRemainingSeconds: Int
    let gameRemainingSeconds: Int
    let isPaused: Bool
}

struct GameInputContext {
    let guessBinding: Binding<String>
    let isPaused: Bool
    let isDisabledSubmitButton: Bool
    let guessInputErrorMessage: String
}

struct GuessesListContext {
    let guesses: [String]
    let guessDurations: [Int]
    let answer: String
    let selectedBullAssetName: String
    let selectedCowAssetName: String
}

struct GameFooterContext {
    let showGuessCount: Bool
    let guessesCount: Int
    let maximumGuesses: Int
    let canSurrender: Bool
}
