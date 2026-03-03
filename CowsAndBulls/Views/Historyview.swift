//
//  Historyview.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

/// Displays previously finished games with filter/sort controls and expandable rows.
struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var showClearConfirmation = false
    @AppStorage("selectedBullAssetName") private var selectedBullAssetName = "Bull"
    @AppStorage("selectedCowAssetName") private var selectedCowAssetName = "Cow"
    @State private var filter: HistoryFilter = .all
    @State private var sort: HistorySort = .newest

    /// Applies the selected filter and sort mode to the stored history items.
    private var displayedItems: [HistoryItem] {
        let filtered: [HistoryItem]
        switch filter {
        case .all:
            filtered = historyStore.items
        case .wins:
            filtered = historyStore.items.filter { $0.finalState }
        case .losses:
            filtered = historyStore.items.filter { $0.finalState == false }
        }

        switch sort {
        case .newest:
            return filtered.sorted { $0.date > $1.date }
        case .oldest:
            return filtered.sorted { $0.date < $1.date }
        case .highestScore:
            return filtered.sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.date > rhs.date
                }
                return lhs.score > rhs.score
            }
        }
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(HistoryFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Sort", selection: $sort) {
                    ForEach(HistorySort.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 128)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)

            ScrollView {
                if historyStore.items.isEmpty {
                    // ContentUnavailableView is a macOS/iOS system empty-state component.
                    // It gives a consistent, native "no data" UX with minimal custom code.
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Play a few rounds and your history will appear here.")
                    )
                    .padding(.top, 40)
                } else if displayedItems.isEmpty {
                    ContentUnavailableView(
                        "No Matching Games",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try a different filter.")
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(displayedItems) { item in
                            HistoryRow(
                                item: item,
                                bullAssetName: selectedBullAssetName,
                                cowAssetName: selectedCowAssetName
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .help(localized("List of your previous attempts."))
        }
        .toolbar {
            // confirmationAction placement puts the action in the expected trailing toolbar position on macOS.
            ToolbarItem(id: "Clear history", placement: .confirmationAction) {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.accent)
                }
                .help(localized("Clear your entire history."))
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

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case wins
    case losses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return localized("history.filter.all")
        case .wins: return localized("history.filter.wins")
        case .losses: return localized("history.filter.losses")
        }
    }
}

private enum HistorySort: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case highestScore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: return localized("history.sort.newest")
        case .oldest: return localized("history.sort.oldest")
        case .highestScore: return localized("history.sort.best_score")
        }
    }
}

/// A compact card for one finished game with an optional expanded guess list.
struct HistoryRow: View {
    let item: HistoryItem
    let bullAssetName: String
    let cowAssetName: String

    @State private var isExpanded = false

    var body: some View {
        // GroupBox gives us a compact card-like section style without building a custom container.
        GroupBox(content: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.finalState ? "✅ \(String(localized: "history.state.won"))" : "❌ \(String(localized: "history.state.lost"))")
                        .fontWeight(.bold)

                    Spacer()

                    Text(item.formattedDate())
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text("Answer: \(item.answer)")
                Text(localized("history.row.steps_score", item.steps, item.maxSteps, item.score))
                Text(
                    localized(
                        "history.row.mode",
                        String(localized: item.hardMode ? "game.mode.hard" : "game.mode.normal"),
                        item.answer.count,
                        String(localized: item.enableRepeats ? "game.mode.repeats" : "game.mode.unique")
                    )
                )
                
                if item.hasPerGuessLimit || item.hasTotalTimeLimit {
                    HStack(alignment: .center, spacing: 2) {

                        if item.hasPerGuessLimit {
                            Text("⏱ Per guess: \(item.perGuessLimit) sec")
                                .padding(.trailing, 6)
                        }
                        

                        if item.hasTotalTimeLimit {
                            Text("🕒 Game limit: \(item.totalTimeLimit) sec")
                        }
                    }
                }
                

                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(Color.accentColor)
                        Text(localized("history.row.view_guesses", item.guesses.count))
                    }
                    .font(.subheadline)
                }
                // Plain style prevents macOS default button chrome from fighting this row design.
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(item.guesses.enumerated()), id: \.offset) { index, guess in
                            HStack {
                                Text("\(guess): ")
                                    .monospacedDigit()
                                GuessResultIcons(
                                    result: item.guessResults[index],
                                    bullAssetName: bullAssetName,
                                    cowAssetName: cowAssetName
                                )
                                let duration = index < item.guessDurations.count ? item.guessDurations[index] : 0
                                Text(GameLogic.formatDuration(TimeInterval(duration)))
                            }
                            .font(.caption)
                        }
                    }
                    // Combined transition feels smoother than move-only for this expandable details block.
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding(6)
        })
    }
}

/// Renders bull/cow feedback as themed icons from encoded history result strings.
struct GuessResultIcons: View {
    let result: String
    let bullAssetName: String
    let cowAssetName: String

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
                        Image(bullAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }

                    ForEach(0..<counts.cows, id: \.self) { _ in
                        Image(cowAssetName)
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
