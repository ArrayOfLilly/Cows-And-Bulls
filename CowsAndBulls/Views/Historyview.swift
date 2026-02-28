//
//  Historyview.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if historyStore.items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.title2)
                            .fontDesign(.rounded)

                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Play a few rounds and your history will appear here.")
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            } else {
                VStack {
                    Text("History")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .padding()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(historyStore.items) { item in
                                HistoryRow(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .help("List of your previous attempts.")
                }
            }
        }
        .toolbar {
            ToolbarItem(id: "Clear history", placement: .confirmationAction) {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .help("Clear your entire history.")
                .disabled(historyStore.items.isEmpty)
            }
        }
        .navigationTitle("Cows and Bulls")
        .frame(maxWidth: .infinity)
        .frame(minHeight: 350, maxHeight: .infinity)
        .confirmationDialog("Clear history?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                historyStore.clear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all saved games.")
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
        GroupBox {
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
                            .foregroundStyle(Color.accentColor)
                        Text("View Guesses (\(item.guesses.count))")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain) // Important for macOS

                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(item.guesses.enumerated()), id: \.offset) { index, guess in
                            HStack {
                                Text("\(item.guesses.count - index < 10 ? "0" : "")\(item.guesses.count - index). \(guess): ")
                                    .monospacedDigit()
                                GuessResultIcons(result: item.guessResults[index])
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
}

struct GuessResultIcons: View {
    let result: String

    private var counts: (bulls: Int, cows: Int)? {
        let components = result.split(separator: "|")
        if components.count == 2,
           let bulls = Int(components[0]),
           let cows = Int(components[1]) {
            return (bulls, cows)
        }

        let bulls = result.filter { $0 == "🟢" }.count
        let cows = result.filter { $0 == "⚪" }.count
        if bulls > 0 || cows > 0 {
            return (bulls, cows)
        }

        return nil
    }

    var body: some View {
        if let counts {
            if counts.bulls == 0 && counts.cows == 0 {
                Text("0")
            } else {
                HStack(spacing: 4) {
                    ForEach(0..<counts.bulls, id: \.self) { _ in
                        Image("Bull")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }

                    ForEach(0..<counts.cows, id: \.self) { _ in
                        Image("Cow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                }
            }
        } else {
            Text(result)
        }
    }
}
