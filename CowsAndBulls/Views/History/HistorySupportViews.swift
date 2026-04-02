//
//  HistorySupportViews.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza.
//

import SwiftUI

struct HistoryControlsRow: View {
    @Binding var filter: HistoryFilter
    @Binding var sort: HistorySort

    var body: some View {
        HStack(spacing: 12) {
            Picker(localized("history.filter.title"), selection: $filter) {
                ForEach(HistoryFilter.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            Picker(localized("history.sort.title"), selection: $sort) {
                ForEach(HistorySort.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 128)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
}

struct HistoryContentView: View {
    let allItems: [HistoryItem]
    let displayedItems: [HistoryItem]
    let bullAssetName: String
    let cowAssetName: String
    let onDelete: (HistoryItem) -> Void

    var body: some View {
        ScrollView {
            if allItems.isEmpty {
                HistoryEmptyStateView(
                    title: localized("history.empty.title"),
                    systemImage: "clock.arrow.circlepath",
                    description: localized("history.empty.description")
                )
            } else if displayedItems.isEmpty {
                HistoryEmptyStateView(
                    title: localized("history.filtered_empty.title"),
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: localized("history.filtered_empty.description")
                )
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(displayedItems) { item in
                        HistoryRow(
                            item: item,
                            bullAssetName: bullAssetName,
                            cowAssetName: cowAssetName,
                            onDelete: {
                                onDelete(item)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .help(localized("history.help.list"))
    }
}

struct HistoryEmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .padding(.top, 40)
    }
}

struct HistoryClearToolbarButton: View {
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(role: .destructive, action: onTap) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.accent)
        }
        .help(localized("history.help.clear"))
        .disabled(isDisabled)
    }
}

enum HistoryFilter: String, CaseIterable, Identifiable {
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

enum HistorySort: String, CaseIterable, Identifiable {
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
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HistoryRowHeader(item: item, onDelete: onDelete)
                HistoryRowSummary(item: item)
                HistoryRowTimers(item: item)
                HistoryRowToggle(isExpanded: $isExpanded, guessesCount: item.guesses.count)

                if isExpanded {
                    HistoryGuessList(
                        item: item,
                        bullAssetName: bullAssetName,
                        cowAssetName: cowAssetName
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding(6)
        }
    }
}

private struct HistoryRowHeader: View {
    let item: HistoryItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(item.finalState ? "✅ \(String(localized: "history.state.won"))" : "❌ \(String(localized: "history.state.lost"))")
                .fontWeight(.bold)

            Spacer()

            Text(item.formattedDate())
                .font(.caption)
                .foregroundColor(.gray)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(localized("history.row.delete"))
        }
    }
}

private struct HistoryRowSummary: View {
    let item: HistoryItem

    var body: some View {
        Text(localized("history.row.answer", item.answer))
        Text(localized("history.row.steps_score", item.steps, item.maxSteps, item.score))
        Text(
            localized(
                "history.row.mode",
                String(localized: item.hardMode ? "game.mode.hard" : "game.mode.normal"),
                item.answer.count,
                String(localized: item.enableRepeats ? "game.mode.repeats" : "game.mode.unique")
            )
        )
    }
}

private struct HistoryRowTimers: View {
    let item: HistoryItem

    var body: some View {
        if item.hasPerGuessLimit || item.hasTotalTimeLimit {
            HStack(alignment: .center, spacing: 2) {
                if item.hasPerGuessLimit {
                    Text(localized("history.row.timer.per_guess", item.perGuessLimit))
                        .padding(.trailing, 6)
                }

                if item.hasTotalTimeLimit {
                    Text(localized("history.row.timer.game", item.totalTimeLimit))
                }
            }
        }
    }
}

private struct HistoryRowToggle: View {
    @Binding var isExpanded: Bool
    let guessesCount: Int

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundStyle(Color.accentColor)
                Text(localized("history.row.view_guesses", guessesCount))
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
    }
}

private struct HistoryGuessList: View {
    let item: HistoryItem
    let bullAssetName: String
    let cowAssetName: String

    var body: some View {
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
                    .animalIconStyle()
                    let duration = index < item.guessDurations.count ? item.guessDurations[index] : 0
                    Text(GameLogic.formatDuration(TimeInterval(duration)))
                }
                .font(.caption)
            }
        }
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
