import Testing
import Foundation
@testable import Cows___Bulls

/// Tests for the HistoryStore. This suite ensures data is correctly stored
/// in memory and persists to the permanent storage (UserDefaults).
@Suite("History Storage (HistoryStore) Tests")
struct HistoryStoreTests {
    /// Helper to create a clean store for every test.
    /// This prevents tests from interfering with each other's data.
    private func setupStore(
        suiteName: String = "HistoryStoreTests.\(UUID().uuidString)",
        storageKey: String = "history.tests"
    ) -> HistoryStore {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HistoryStore(userDefaults: defaults, storageKey: storageKey)
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
        #expect(item?.endReason == .completed)
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
        let suiteName = "HistoryStoreTests.persistence.\(UUID().uuidString)"
        let storageKey = "history.tests.persistence"
        let store = setupStore(suiteName: suiteName, storageKey: storageKey)
        store.add(finalState: true, answer: "PERSISTENT", steps: 1, score: 100, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: [], guessResults: [], duration: 34, hasPerGuessLimit: true, hasTotalTimeLimit: false, perGuessLimit: 15, totalTimeLimit: 300, guessDurations: [])

        // Create a completely separate instance of HistoryStore.
        // Since both use the same UserDefaults suite/key, they share backend data.
        let secondDefaults = UserDefaults(suiteName: suiteName)!
        let secondInstance = HistoryStore(userDefaults: secondDefaults, storageKey: storageKey)
        #expect(secondInstance.items.contains(where: { $0.answer == "PERSISTENT" }))
    }

    @Test("Verify that HistoryItem date formatting matches the expected structure")
    func historyItemDateFormat() {
        let item = HistoryItem(duration: 1000, hasPerGuessLimit: true, hasTotalTimeLimit: true, perGuessLimit: 15, totalTimeLimit: 1000, guessDurations: [12, 6], finalState: true, answer: "1234", steps: 2, score: 788, maxSteps: 15, hardMode: false, enableRepeats: true, guesses: ["1243", "1234"], guessResults: [])
        let formattedDate = item.formattedDate()

        // Expecting "dd/MM/yyyy HH:mm:ss" which always results in 19 characters.
        #expect(formattedDate.count == 19)
    }

    @Test("Timeout end reason is persisted with history item")
    func timeoutEndReasonPersists() {
        let suiteName = "HistoryStoreTests.timeout.\(UUID().uuidString)"
        let storageKey = "history.tests.timeout"
        let store = setupStore(suiteName: suiteName, storageKey: storageKey)

        store.add(
            finalState: false,
            answer: "TIMEOUT",
            steps: 0,
            score: 0,
            maxSteps: 10,
            hardMode: false,
            enableRepeats: false,
            guesses: [],
            guessResults: [],
            duration: 12,
            hasPerGuessLimit: true,
            hasTotalTimeLimit: false,
            perGuessLimit: 15,
            totalTimeLimit: 300,
            guessDurations: [],
            endReason: .timeoutPerGuess
        )

        let secondDefaults = UserDefaults(suiteName: suiteName)!
        let secondInstance = HistoryStore(userDefaults: secondDefaults, storageKey: storageKey)
        #expect(secondInstance.items.first?.endReason == .timeoutPerGuess)
    }

    @Test("History data is isolated per profile id")
    func profileHistoryIsolation() {
        let suiteName = "HistoryStoreTests.profiles.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HistoryStore(userDefaults: defaults)

        store.setActiveProfileId("A")
        store.add(
            finalState: true,
            answer: "1234",
            steps: 1,
            score: 50,
            maxSteps: 10,
            hardMode: false,
            enableRepeats: false,
            guesses: ["1234"],
            guessResults: ["4|0"],
            duration: 10,
            hasPerGuessLimit: false,
            hasTotalTimeLimit: false,
            perGuessLimit: 0,
            totalTimeLimit: 0,
            guessDurations: [10]
        )

        store.setActiveProfileId("B")
        #expect(store.items.isEmpty)

        store.setActiveProfileId("A")
        #expect(store.items.count == 1)
    }

    @Test("Deleting profile data clears only that profile")
    func deleteProfileDataClearsOnlyTarget() {
        let suiteName = "HistoryStoreTests.deleteProfile.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HistoryStore(userDefaults: defaults)

        store.setActiveProfileId("A")
        store.add(finalState: true, answer: "AAAA", steps: 1, score: 10, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: ["AAAA"], guessResults: ["4|0"], duration: 5, hasPerGuessLimit: false, hasTotalTimeLimit: false, perGuessLimit: 0, totalTimeLimit: 0, guessDurations: [5])

        store.setActiveProfileId("B")
        store.add(finalState: true, answer: "BBBB", steps: 1, score: 10, maxSteps: 10, hardMode: false, enableRepeats: false, guesses: ["BBBB"], guessResults: ["4|0"], duration: 5, hasPerGuessLimit: false, hasTotalTimeLimit: false, perGuessLimit: 0, totalTimeLimit: 0, guessDurations: [5])

        store.deleteProfileData(profileId: "A")

        store.setActiveProfileId("A")
        #expect(store.items.isEmpty)

        store.setActiveProfileId("B")
        #expect(store.items.count == 1)
    }

    @Test("Clearing history marks the profile as modified and persists that flag")
    func clearMarksHistoryModified() {
        let suiteName = "HistoryStoreTests.clearModified.\(UUID().uuidString)"
        let storageKey = "history.tests.clearModified"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HistoryStore(userDefaults: defaults, storageKey: storageKey)

        #expect(store.isHistoryModified == false)

        store.clear()

        #expect(store.isHistoryModified == true)

        let secondInstance = HistoryStore(userDefaults: defaults, storageKey: storageKey)
        #expect(secondInstance.isHistoryModified == true)
    }

    @Test("Deleting a history item marks the profile as modified")
    func deleteMarksHistoryModified() throws {
        let suiteName = "HistoryStoreTests.deleteModified.\(UUID().uuidString)"
        let storageKey = "history.tests.deleteModified"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HistoryStore(userDefaults: defaults, storageKey: storageKey)

        store.add(
            finalState: true,
            answer: "1234",
            steps: 1,
            score: 10,
            maxSteps: 10,
            hardMode: false,
            enableRepeats: false,
            guesses: ["1234"],
            guessResults: ["4|0"],
            duration: 5,
            hasPerGuessLimit: false,
            hasTotalTimeLimit: false,
            perGuessLimit: 0,
            totalTimeLimit: 0,
            guessDurations: [5]
        )

        let item = try #require(store.items.first)
        #expect(store.isHistoryModified == false)

        store.delete(item)

        #expect(store.isHistoryModified == true)

        let secondInstance = HistoryStore(userDefaults: defaults, storageKey: storageKey)
        #expect(secondInstance.isHistoryModified == true)
    }

    @Test("Adding a prebuilt HistoryItem stores it unchanged")
    func addPrebuiltHistoryItem() throws {
        let store = setupStore()
        let item = HistoryItem(
            duration: 42,
            hasPerGuessLimit: true,
            hasTotalTimeLimit: true,
            perGuessLimit: 15,
            totalTimeLimit: 600,
            guessDurations: [10, 12],
            finalState: false,
            answer: "9876",
            steps: 2,
            score: 0,
            maxSteps: 8,
            hardMode: true,
            enableRepeats: true,
            guesses: ["1234", "9876"],
            guessResults: ["1|1", "4|0"],
            endReason: .surrender
        )

        store.add(item)

        let stored = try #require(store.items.first)
        #expect(stored.answer == item.answer)
        #expect(stored.endReason == .surrender)
        #expect(stored.guessDurations == [10, 12])
    }

    @Test("Legacy history migrates into the first selected profile")
    func legacyHistoryMigratesToSelectedProfile() {
        let suiteName = "HistoryStoreTests.legacy.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyItems = [
            HistoryItem(
                duration: 9,
                hasPerGuessLimit: false,
                hasTotalTimeLimit: false,
                perGuessLimit: 0,
                totalTimeLimit: 0,
                guessDurations: [9],
                finalState: true,
                answer: "1111",
                steps: 1,
                score: 99,
                maxSteps: 10,
                hardMode: false,
                enableRepeats: false,
                guesses: ["1111"],
                guessResults: ["4|0"]
            )
        ]
        defaults.set(try? JSONEncoder().encode(legacyItems), forKey: "history")
        defaults.set(true, forKey: "history.modified")

        let store = HistoryStore(userDefaults: defaults)
        store.setActiveProfileId("A")

        #expect(store.items.count == 1)
        #expect(store.items.first?.answer == "1111")
        #expect(store.isHistoryModified == true)
        #expect(defaults.data(forKey: "history") == nil)
    }
}
