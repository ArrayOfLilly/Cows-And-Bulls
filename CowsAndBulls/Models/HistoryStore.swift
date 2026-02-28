//
//  HistoryStore.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import Foundation
import SwiftUI
internal import Combine

struct HistoryItem: Identifiable, Codable {
    var id: UUID = UUID()        // unique ID
    var date: Date = Date()      // timestamp when saved
    var finalState: Bool
    var answer: String
    var steps: Int
    var score: Int
    var maxSteps: Int
    var hardMode: Bool
    var enableRepeats: Bool
    var guesses: [String]
    var guessResults: [String]
    
    // Format date as dd/MM/yyyy HH:mm:ss
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
}

class HistoryStore: ObservableObject {
    @AppStorage("history") private var historyData: Data = Data()
    @Published var items: [HistoryItem] = []
    
    init() {
        load()
    }
    
    private func load() {
        if let decoded = try? JSONDecoder().decode([HistoryItem].self, from: historyData) {
            items = decoded
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            historyData = encoded
        }
    }
    
    func add(finalState: Bool, answer: String, steps: Int, score: Int, maxSteps: Int, hardMode: Bool, enableRepeats: Bool, guesses: [String], guessResults: [String]) {
        let newItem = HistoryItem(
            finalState: finalState,
            answer: answer,
            steps: steps,
            score: score,
            maxSteps: maxSteps,
            hardMode: hardMode,
            enableRepeats: enableRepeats,
            guesses: guesses,
            guessResults: guessResults
            
        )
        items.insert(newItem, at: 0) // newest first
        save()
    }
    
    func clear() {
        items.removeAll()
        save()
    }
    
    var totalScore: Int {
        items.reduce(0) { $0 + $1.score }
    }
}
