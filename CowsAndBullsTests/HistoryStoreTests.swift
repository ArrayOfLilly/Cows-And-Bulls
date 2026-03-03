import Testing
import Foundation
@testable import Cows___Bulls

/// Tests for the HistoryStore. This suite ensures data is correctly stored
/// in memory and persists to the permanent storage (UserDefaults).
@Suite("History Storage (HistoryStore) Tests")
struct HistoryStoreTests {

    /// Helper to create a clean store for every test.
    /// This prevents tests from interfering with each other's data.
    private func setupStore() -> HistoryStore {
        let store = HistoryStore()
        store.clear()
        return store
    }

    @Test("Adding a game result preserves all item metadata correctly")
    func addHistoryItemMetadata() {
        let store = setupStore()
        let guesses = ["1234", "5678"]
        let results = ["2|1", "4|0"]
        let guessDurations: [Int] = [12, 6]

        store.add(
            finalState: true,
            answer: "5678",
            steps: 2,
            score: 1250,
            maxSteps: 10,
            hardMode: true,
            enableRepeats: false,
            guesses: guesses,
            guessResults: results,
            duration: 34,
            hasPerGuessLimit: true,
            hasTotalTimeLimit: false,
            perGuessLimit: 15,
            totalTimeLimit: 300,
            guessDurations: guessDurations
        )

        // Verify that the saved item properties exactly match what we passed in.
        let item = store.items.first
        #expect(item?.answer == "5678")
        #expect(item?.score == 1250)
        #expect(item?.hardMode == true)
        #expect(item?.guesses == guesses)
        #expect(item?.guessResults == results)
    }

    @Test("LIFO ordering check: Newest games must appear at the top of the list")
    func itemsOrdering() {
        let store = setupStore()

        store.add(finalState: true, answer: "OLD", steps: 1, score: 10, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [12, 6])
        store.add(finalState: true, answer: "NEW", steps: 1, score: 10, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [12, 6])
    
        // LIFO (Last In, First Out) means "NEW" should be at index 0.
        #expect(store.items[0].answer == "NEW")
        #expect(store.items[1].answer == "OLD")
    }

    @Test("Correct calculation of total accumulated score across multiple games")
    func totalScoreCalculation() {
        let store = setupStore()

        store.add(finalState: true, answer: "A", steps: 1, score: 100, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [12, 6])
        store.add(finalState: true, answer: "B", steps: 1, score: 250, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [12, 6])

        #expect(store.totalScore == 350)
    }

    @Test("Persistence check: Data remains available even after creating a new store instance")
    func persistenceCheck() {
        let store = setupStore()
        store.add(finalState: true, answer: "PERSISTENT", steps: 1, score: 100, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [])

        // Create a completely separate instance of HistoryStore.
        // Since both use @AppStorage on the same key, they share the same backend data.
        let secondInstance = HistoryStore()
        #expect(secondInstance.items.contains(where: { $0.answer == "PERSISTENT" }))
    }

    @Test("Verify that HistoryItem date formatting matches the expected structure")
    func historyItemDateFormat() {
        let item = HistoryItem(duration: 1000, hasPerGuessLimit: true, hasTotalTimeLimit: true, perGuessLimit: 15, totalTimeLimit: 1000, guessDurations: [12, 6], finalState: true, answer: "1234", steps: 2, score: 788, maxSteps: 15, hardMode: false, enableRepeats: true, guesses: ["1243", "1234"], guessResults: [])
        let formattedDate = item.formattedDate()

        // Expecting "dd/MM/yyyy HH:mm:ss" which always results in 19 characters.
        #expect(formattedDate.count == 19)
    }
}
