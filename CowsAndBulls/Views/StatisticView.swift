//
//  StatisticView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 28..
//

import SwiftUI

struct StatisticView: View {
    @EnvironmentObject private var historyStore: HistoryStore

    // MARK: - Computed Data

    private var items: [HistoryItem] {
        historyStore.items
    }

    private var totalGames: Int {
        items.count
    }

    private var wonGames: Int {
        items.filter { $0.finalState }.count
    }

    private var lostGames: Int {
        totalGames - wonGames
    }

    private var totalScore: Int {
        items.reduce(0) { $0 + $1.score }
    }

    private var totalSteps: Int {
        items.reduce(0) { $0 + $1.steps }
    }

    private var averageScore: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalScore) / Double(totalGames)
    }

    private var averageSteps: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalSteps) / Double(totalGames)
    }

    private var averageStepRatio: Double {
        guard totalGames > 0 else { return 0 }

        let totalRatio = items.reduce(0.0) { partial, item in
            guard item.maxSteps > 0 else { return partial }
            return partial + (Double(item.steps) / Double(item.maxSteps))
        }

        return totalRatio / Double(totalGames)
    }

    private var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return (Double(wonGames) / Double(totalGames)) * 100
    }

    private var mostUsedMode: String {
        guard totalGames > 0 else { return localized("-") }

        let hardCount = items.filter { $0.hardMode }.count
        let normalCount = totalGames - hardCount

        if hardCount == normalCount {
            return localized("Tie")
        }

        return hardCount > normalCount ? localized("Hard") : localized("Normal")
    }

    private var mostUsedLength: String {
        guard totalGames > 0 else { return localized("-") }

        var lengthCounts: [Int: Int] = [:]
        for item in items {
            lengthCounts[item.answer.count, default: 0] += 1
        }

        guard let best = lengthCounts.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }) else {
            return localized("-")
        }

        return localized("%lld digits", best.key)
    }

    private var mostUsedRepeats: String {
        guard totalGames > 0 else { return localized("-") }

        let repeatsOnCount = items.filter { $0.enableRepeats }.count
        let repeatsOffCount = totalGames - repeatsOnCount

        if repeatsOnCount == repeatsOffCount {
            return localized("Tie")
        }

        return repeatsOnCount > repeatsOffCount ? localized("Repeats On") : localized("Repeats Off")
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Statistics")
                    .font(.title2)
                    .fontDesign(.rounded)

                if items.isEmpty {
                    ContentUnavailableView("No Data Yet", systemImage: "chart.bar")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    overviewSection
                    performanceSection
                    settingsSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Statistics")
        .frame(maxWidth: .infinity)
        .frame(minHeight: 350, maxHeight: .infinity)
        .tabItem {
            Label("Stats", systemImage: "chart.xyaxis.line")
        }
    }

    // MARK: - Sections

    private var overviewSection: some View {
        GroupBox(localized("Overview")) {
            statisticRow(localized("Total games"), value: "\(totalGames)")
            statisticRow(localized("Wins"), value: "\(wonGames)")
            statisticRow(localized("Losses"), value: "\(lostGames)")
            statisticRow(localized("Win rate"), value: "\(formatted(winRate, decimals: 1))%")
        }
    }

    private var performanceSection: some View {
        GroupBox(localized("Performance")) {
            statisticRow(localized("Total score"), value: "\(totalScore)")
            statisticRow(localized("Average score"), value: formatted(averageScore, decimals: 1))
            statisticRow(localized("Average steps"), value: formatted(averageSteps, decimals: 2))
            statisticRow(localized("Average step ratio"), value: formatted(averageStepRatio, decimals: 2))
        }
    }

    private var settingsSection: some View {
        GroupBox(localized("Most Used Settings")) {
            statisticRow(localized("Mode"), value: mostUsedMode)
            statisticRow(localized("Answer length"), value: mostUsedLength)
            statisticRow(localized("Repeats"), value: mostUsedRepeats)
        }
    }

    // MARK: - Helpers

    private func formatted(_ value: Double, decimals: Int) -> String {
        String(format: "%.*f", decimals, value)
    }

    @ViewBuilder
    private func statisticRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    StatisticView()
        .environmentObject(HistoryStore())
}
