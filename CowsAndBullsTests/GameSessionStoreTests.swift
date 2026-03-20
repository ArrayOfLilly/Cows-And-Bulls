import Testing
import Foundation
@testable import Cows___Bulls

@MainActor
@Suite("Game Session Store Tests")
struct GameSessionStoreTests {
    @Test("Gameplay settings are locked while a game is running")
    func gameplaySettingsLockedWhileRunning() {
        let store = GameSessionStore()

        #expect(store.canEditGameplaySettings == true)

        store.beginGame(with: .default)
        #expect(store.canEditGameplaySettings == false)

        store.finishGame()
        #expect(store.canEditGameplaySettings == true)
    }

    @Test("Reset clears session state")
    func resetClearsState() {
        let store = GameSessionStore()

        store.beginGame(with: .default)
        store.recordSubmittedGuess()
        store.resetSession()

        #expect(store.gameInProgress == false)
        #expect(store.hasSubmittedGuess == false)
        #expect(store.startedSettingsSnapshot == nil)
    }

    @Test("Ticking the timers counts down to expiration")
    func timerTicksDownToExpiration() {
        let store = GameSessionStore()
        var settings = ProfileSettings.default
        settings.enablePerGuessTimeLimit = true
        settings.perGuessTimeLimitSeconds = 2
        settings.enableGameTimeLimit = true
        settings.gameTimeLimitSeconds = 2

        store.beginGame(with: settings)

        #expect(store.tickPerGuessSecond() == false)
        #expect(store.perGuessRemainingSeconds == 1)
        #expect(store.tickPerGuessSecond() == true)
        #expect(store.perGuessRemainingSeconds == 0)

        #expect(store.tickGameSecond() == false)
        #expect(store.gameRemainingSeconds == 1)
        #expect(store.tickGameSecond() == true)
        #expect(store.gameRemainingSeconds == 0)
    }

    @Test("Pause shifts measured durations forward after resume")
    func pauseDoesNotCountTowardGuessDuration() {
        let store = GameSessionStore()
        let start = Date(timeIntervalSinceReferenceDate: 1_000)

        store.beginGame(with: .default, at: start)
        store.pause(at: start.addingTimeInterval(5))
        store.resume(at: start.addingTimeInterval(20))
        store.recordSubmittedGuess(at: start.addingTimeInterval(30))

        #expect(store.guessDurations == [15])
    }

    @Test("Window-close pause resumes only when marked for window close")
    func windowClosePauseResume() {
        let store = GameSessionStore()
        let start = Date(timeIntervalSinceReferenceDate: 3_000)

        store.beginGame(with: .default, at: start)
        store.pause(at: start.addingTimeInterval(5), dueToWindowClose: true)

        #expect(store.isPaused == true)
        #expect(store.resumeAfterWindowCloseIfNeeded(at: start.addingTimeInterval(10)) == true)
        #expect(store.isPaused == false)
        #expect(store.resumeAfterWindowCloseIfNeeded(at: start.addingTimeInterval(12)) == false)
    }

    @Test("Timeout and surrender record the expected end reasons")
    func timeoutAndSurrenderSetEndReason() {
        let store = GameSessionStore()
        let start = Date(timeIntervalSinceReferenceDate: 4_000)

        store.beginGame(with: .default, at: start)
        store.markTimeout(.timeoutPerGuess, at: start.addingTimeInterval(8))
        #expect(store.gameInProgress == false)
        #expect(store.timeoutEndReason == .timeoutPerGuess)

        store.beginGame(with: .default, at: start.addingTimeInterval(10))
        store.markSurrender(at: start.addingTimeInterval(15))
        #expect(store.timeoutEndReason == .surrender)
    }

    @Test("History items use the session-start gameplay settings snapshot")
    func historyItemUsesStartedSettings() {
        let store = GameSessionStore()
        var initialSettings = ProfileSettings.default
        initialSettings.maximumGuesses = 12
        initialSettings.enableRepeats = true
        initialSettings.enablePerGuessTimeLimit = true
        initialSettings.perGuessTimeLimitSeconds = 25

        let start = Date(timeIntervalSinceReferenceDate: 2_000)
        store.beginGame(with: initialSettings, at: start)
        store.recordSubmittedGuess(at: start.addingTimeInterval(7))
        store.finishGame(at: start.addingTimeInterval(21))

        var changedSettings = initialSettings
        changedSettings.maximumGuesses = 6
        changedSettings.enableRepeats = false
        changedSettings.perGuessTimeLimitSeconds = 10

        let item = store.makeHistoryItem(
            finalState: true,
            answer: "1234",
            guesses: ["1234"],
            score: 500,
            currentSettings: changedSettings
        )

        #expect(item?.maxSteps == 12)
        #expect(item?.enableRepeats == true)
        #expect(item?.perGuessLimit == 25)
        #expect(item?.duration == 21)
    }

    @Test("History is not created when no guess was submitted")
    func historyRequiresAtLeastOneGuess() {
        let store = GameSessionStore()
        let start = Date(timeIntervalSinceReferenceDate: 5_000)

        store.beginGame(with: .default, at: start)
        store.finishGame(at: start.addingTimeInterval(3))

        let item = store.makeHistoryItem(
            finalState: false,
            answer: "1234",
            guesses: [],
            score: 0,
            currentSettings: .default
        )

        #expect(item == nil)
    }
}
