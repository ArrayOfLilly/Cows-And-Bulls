//
//  HistoryStore.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import Foundation
import SwiftUI
internal import Combine

/// A persisted snapshot of one finished game, including timing and difficulty settings.
struct HistoryItem: Identifiable, Codable {
    enum EndReason: String, Codable {
        case completed
        case timeoutPerGuess
        case timeoutGame
        case surrender
    }

    var id: UUID = UUID()
    var date: Date = Date()
    var duration: TimeInterval = 0 // Total game duration
    
    // Timing configuration flags
    var hasPerGuessLimit: Bool = false
    var hasTotalTimeLimit: Bool = false
    var perGuessLimit: Int = 0
    var totalTimeLimit: Int = 0
    
    // Time taken for each individual guess in seconds
    var guessDurations: [Int] = []
    
    var finalState: Bool
    var answer: String
    var steps: Int
    var score: Int
    var maxSteps: Int
    var hardMode: Bool
    var enableRepeats: Bool
    var guesses: [String]
    var guessResults: [String]
    var endReason: EndReason = .completed
    
    enum CodingKeys: String, CodingKey {
        case id, date, duration, hasPerGuessLimit, hasTotalTimeLimit, perGuessLimit, totalTimeLimit, guessDurations, finalState, answer, steps, score, maxSteps, hardMode, enableRepeats, guesses, guessResults, endReason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        // decodeIfPresent defaults keep older history payloads readable after schema changes.
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        hasPerGuessLimit = try container.decodeIfPresent(Bool.self, forKey: .hasPerGuessLimit) ?? false
        hasTotalTimeLimit = try container.decodeIfPresent(Bool.self, forKey: .hasTotalTimeLimit) ?? false
        perGuessLimit = try container.decodeIfPresent(Int.self, forKey: .perGuessLimit) ?? 0
        totalTimeLimit = try container.decodeIfPresent(Int.self, forKey: .totalTimeLimit) ?? 0
        guessDurations = try container.decodeIfPresent([Int].self, forKey: .guessDurations) ?? []
        finalState = try container.decode(Bool.self, forKey: .finalState)
        answer = try container.decode(String.self, forKey: .answer)
        steps = try container.decode(Int.self, forKey: .steps)
        score = try container.decode(Int.self, forKey: .score)
        maxSteps = try container.decode(Int.self, forKey: .maxSteps)
        hardMode = try container.decode(Bool.self, forKey: .hardMode)
        enableRepeats = try container.decode(Bool.self, forKey: .enableRepeats)
        guesses = try container.decode([String].self, forKey: .guesses)
        guessResults = try container.decode([String].self, forKey: .guessResults)
        endReason = try container.decodeIfPresent(EndReason.self, forKey: .endReason) ?? .completed
    }
    
    init(duration: TimeInterval, hasPerGuessLimit: Bool, hasTotalTimeLimit: Bool, perGuessLimit: Int, totalTimeLimit: Int, guessDurations: [Int], finalState: Bool, answer: String, steps: Int, score: Int, maxSteps: Int, hardMode: Bool, enableRepeats: Bool, guesses: [String], guessResults: [String], endReason: EndReason = .completed) {
        self.duration = duration
        self.hasPerGuessLimit = hasPerGuessLimit
        self.hasTotalTimeLimit = hasTotalTimeLimit
        self.perGuessLimit = perGuessLimit
        self.totalTimeLimit = totalTimeLimit
        self.guessDurations = guessDurations
        self.finalState = finalState
        self.answer = answer
        self.steps = steps
        self.score = score
        self.maxSteps = maxSteps
        self.hardMode = hardMode
        self.enableRepeats = enableRepeats
        self.guesses = guesses
        self.guessResults = guessResults
        self.endReason = endReason
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    var isTimed: Bool {
        hasPerGuessLimit || hasTotalTimeLimit
    }
}

class HistoryStore: ObservableObject {
    private let userDefaults: UserDefaults
    private var storageKey: String
    private var modifiedKey: String
    @Published var items: [HistoryItem] = []
    @Published private(set) var isHistoryModified = false
    
    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "history"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.modifiedKey = "\(storageKey).modified"
        load()
    }
    
    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            items = []
            isHistoryModified = userDefaults.bool(forKey: modifiedKey)
            return
        }
        if let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = decoded
        } else {
            items = []
        }
        isHistoryModified = userDefaults.bool(forKey: modifiedKey)
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    func setActiveProfileId(_ profileId: String) {
        let nextStorageKey = "history.\(profileId)"
        guard storageKey != nextStorageKey else { return }
        migrateLegacyHistoryIfNeeded(to: profileId)
        storageKey = nextStorageKey
        modifiedKey = "history.\(profileId).modified"
        load()
    }
    
    func add(
        finalState: Bool,
        answer: String,
        steps: Int,
        score: Int,
        maxSteps: Int,
        hardMode: Bool,
        enableRepeats: Bool,
        guesses: [String],
        guessResults: [String],
        duration: TimeInterval,
        hasPerGuessLimit: Bool,
        hasTotalTimeLimit: Bool,
        perGuessLimit: Int,
        totalTimeLimit: Int,
        guessDurations: [Int],
        endReason: HistoryItem.EndReason = .completed
    ) {
        // Newest-first order keeps the most recent game at the top in history/stat views.
        let newItem = HistoryItem(
            duration: duration,
            hasPerGuessLimit: hasPerGuessLimit,
            hasTotalTimeLimit: hasTotalTimeLimit,
            perGuessLimit: perGuessLimit,
            totalTimeLimit: totalTimeLimit,
            guessDurations: guessDurations,
            finalState: finalState,
            answer: answer,
            steps: steps,
            score: score,
            maxSteps: maxSteps,
            hardMode: hardMode,
            enableRepeats: enableRepeats,
            guesses: guesses,
            guessResults: guessResults,
            endReason: endReason
        )
        items.insert(newItem, at: 0)
        save()
    }

    func add(_ item: HistoryItem) {
        items.insert(item, at: 0)
        save()
    }
    
    func clear() {
        items.removeAll()
        save()
        markHistoryModified()
    }
    
    var totalScore: Int {
        items.reduce(0) { $0 + $1.score }
    }

    func delete(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
        markHistoryModified()
    }

    func deleteProfileData(profileId: String) {
        let profileKey = "history.\(profileId)"
        let profileModifiedKey = "history.\(profileId).modified"
        userDefaults.removeObject(forKey: profileKey)
        userDefaults.removeObject(forKey: profileModifiedKey)

        if storageKey == profileKey {
            items = []
            isHistoryModified = false
        }
    }

    func exportedHistory(for profileIDs: [String]) -> [String: [HistoryItem]] {
        Dictionary(uniqueKeysWithValues: profileIDs.map { profileID in
            let key = "history.\(profileID)"
            let value: [HistoryItem]
            if let data = userDefaults.data(forKey: key),
               let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
                value = decoded
            } else {
                value = []
            }
            return (profileID, value)
        })
    }

    func replaceAllHistory(_ importedHistory: [String: [HistoryItem]], activeProfileId: String) {
        removeAllStoredHistory()

        for (profileID, items) in importedHistory {
            let key = "history.\(profileID)"
            if let encoded = try? JSONEncoder().encode(items) {
                userDefaults.set(encoded, forKey: key)
            }
            userDefaults.set(false, forKey: "history.\(profileID).modified")
        }

        storageKey = "history.\(activeProfileId)"
        modifiedKey = "history.\(activeProfileId).modified"
        load()
    }

    private func markHistoryModified() {
        guard isHistoryModified == false else { return }
        isHistoryModified = true
        userDefaults.set(true, forKey: modifiedKey)
    }

    private func removeAllStoredHistory() {
        let keys = userDefaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("history.")
        }
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func migrateLegacyHistoryIfNeeded(to profileId: String) {
        let legacyKey = "history"
        let legacyModifiedKey = "history.modified"
        let profileKey = "history.\(profileId)"
        let profileModifiedKey = "history.\(profileId).modified"

        guard let legacyData = userDefaults.data(forKey: legacyKey) else { return }
        if userDefaults.data(forKey: profileKey) == nil {
            userDefaults.set(legacyData, forKey: profileKey)
            if userDefaults.object(forKey: legacyModifiedKey) != nil {
                userDefaults.set(userDefaults.bool(forKey: legacyModifiedKey), forKey: profileModifiedKey)
            }
        }
        userDefaults.removeObject(forKey: legacyKey)
        userDefaults.removeObject(forKey: legacyModifiedKey)
    }
}
