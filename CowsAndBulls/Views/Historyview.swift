//
//  Historyview.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore

    @State private var expandedItems: Set<UUID> = []

    var body: some View {
        VStack {
            Text("History")
                .font(.title2)
                .fontDesign(.rounded)
                .padding()


            List {
                ForEach(historyStore.items) { item in
                    HistoryRow(item: item)
                }
                    .padding(4)
            }
                .help("List of your previous attempts.")
                .toolbar {
                ToolbarItem(id: "Clear history", placement: .confirmationAction) {
                    Button(role: .destructive, action: historyStore.clear) {
                        Image(systemName: "xmark.circle.fill")
                    }
                        .help("Clear your entire history.")
                }
            }
                .navigationTitle("Cows and Bulls")
                .frame(width: 300)
                .frame(minHeight: 350, maxHeight: .infinity)
                .foregroundStyle(Color.blue)

        }
            .tabItem {
            Label("History", systemImage: "clock.arrow.circlepath")
        }
    }
}

struct HistoryRow: View {
    let item: HistoryItem
    
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text(item.finalState ? "✅ Won" : "❌ Lost")
                    .fontWeight(.bold)

                Spacer()

                Text(item.formattedDate())
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("Answer: \(item.answer)")
            Text("Steps: \(item.steps)/\(item.maxSteps), Score: \(item.score)")
            Text("Game mode: \(item.hardMode ? "Hard" : "Normal"), \(item.answer.count) digits \(item.enableRepeats ? "repeating numbers" : "unique numbers")")

            // Custom toggle button
            Button {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(Color.white)
                    Text("View Guesses (\(item.guesses.count))")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)   // Important for macOS

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(item.guesses.enumerated()), id: \.offset) { index, guess in
                        HStack {
                            Text("\(item.guesses.count - index < 10 ? "0" : "")\(item.guesses.count - index). \(guess): ")
                                .monospacedDigit()
                            Text(item.guessResults[index])
                        }
                        .font(.caption)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(6)
    }
}
