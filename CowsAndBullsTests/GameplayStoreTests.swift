import Testing
@testable import Cows___Bulls

@MainActor
@Suite("Gameplay Store Tests")
struct GameplayStoreTests {
    private func makeSettings(
        answerLength: Int = 4,
        maximumGuesses: Int = 10,
        enableRepeats: Bool = false
    ) -> ProfileSettings {
        var settings = ProfileSettings.default
        settings.answerLength = answerLength
        settings.maximumGuesses = maximumGuesses
        settings.enableRepeats = enableRepeats
        return settings
    }

    @Test("Starting a new game resets presentation state")
    func startNewGameResetsState() {
        let store = GameplayStore()
        let settings = makeSettings()

        store.guess = "9999"
        store.isWon = true
        store.isGameOver = true
        store.isDisabledSubmitButton = true
        store.showAnswer = "answer"
        store.gameOverMessage = "over"

        store.startNewGame(settings: settings)

        #expect(store.answer.count == 4)
        #expect(store.guesses.isEmpty)
        #expect(store.guess.isEmpty)
        #expect(store.isWon == false)
        #expect(store.isGameOver == false)
        #expect(store.isDisabledSubmitButton == false)
        #expect(store.showAnswer.isEmpty)
        #expect(store.gameOverMessage.isEmpty)
    }

    @Test("Submitting a winning guess marks the game as won")
    func submitGuessWin() {
        let store = GameplayStore()
        let settings = makeSettings()

        store.answer = "1234"
        store.guess = "1234"

        let result = store.submitGuess(settings: settings, gameInProgress: true)

        #expect(result == .won)
        #expect(store.guesses == ["1234"])
        #expect(store.isWon == true)
        #expect(store.currentRound == 1)
    }

    @Test("Submitting the last wrong guess marks the game as lost")
    func submitGuessLoss() {
        let store = GameplayStore()
        let settings = makeSettings(maximumGuesses: 1)

        store.answer = "1234"
        store.guess = "9012"

        let result = store.submitGuess(settings: settings, gameInProgress: true)

        #expect(result == .lost)
        #expect(store.isGameOver == true)
        #expect(store.currentRound == 1)
        #expect(store.gameOverMessage.isEmpty == false)
    }

    @Test("Duplicate guesses are rejected when repeats are disabled")
    func duplicateGuessRejected() {
        let store = GameplayStore()
        let settings = makeSettings()

        store.answer = "1234"
        store.guesses = ["1234"]
        store.guess = "1234"

        let result = store.submitGuess(settings: settings, gameInProgress: true)

        #expect(result == .invalid)
        #expect(store.guesses.count == 1)
        #expect(store.guessInputErrorMessage.isEmpty == false)
    }

    @Test("Submitting while no game is active auto-starts from the pending text")
    func submitGuessStartsFromPendingInput() {
        let store = GameplayStore()
        let settings = makeSettings()
        store.guess = "1234"

        let result = store.submitGuess(settings: settings, gameInProgress: false)

        #expect(result == .lost || result == .submitted || result == .won)
        #expect(store.answer.count == 4)
        #expect(store.currentRound == 1)
        #expect(store.guesses.count == 1)
        #expect(store.guesses.first == "1234")
    }

    @Test("Invalid guesses do not advance the round or clear the text")
    func invalidGuessKeepsInputAndRound() {
        let store = GameplayStore()
        let settings = makeSettings()
        store.answer = "1234"
        store.guess = "11"

        let result = store.submitGuess(settings: settings, gameInProgress: true)

        #expect(result == .invalid)
        #expect(store.currentRound == 0)
        #expect(store.guesses.isEmpty)
        #expect(store.guess == "11")
        #expect(store.guessInputErrorMessage.isEmpty == false)
    }

    @Test("Live validation clears when the field becomes empty")
    func liveValidationClearsForEmptyInput() {
        let store = GameplayStore()
        let settings = makeSettings()
        store.guess = "11"
        store.updateLiveGuessValidation(settings: settings)
        #expect(store.guessInputErrorMessage.isEmpty == false)

        store.guess = ""
        store.updateLiveGuessValidation(settings: settings)

        #expect(store.guessInputErrorMessage.isEmpty)
    }

    @Test("Repeated digits are allowed when repeats are enabled")
    func repeatsAllowedWhenEnabled() {
        let store = GameplayStore()
        let settings = makeSettings(enableRepeats: true)
        store.answer = "9988"
        store.guess = "1122"

        let result = store.submitGuess(settings: settings, gameInProgress: true)

        #expect(result == .submitted)
        #expect(store.currentRound == 1)
        #expect(store.guessInputErrorMessage.isEmpty)
    }

    @Test("Finalize loss reveals the answer and disables submission")
    func finalizeLossRevealsAnswer() {
        let store = GameplayStore()
        store.answer = "1234"

        store.finalizeLoss()

        #expect(store.isDisabledSubmitButton == true)
        #expect(store.showAnswer.isEmpty == false)
    }
}
