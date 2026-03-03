//
//  StatisticView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 28..
//

import SwiftUI

/// Aggregates history data into high-level player statistics.
struct StatisticView: View {
    @EnvironmentObject private var historyStore: HistoryStore

    private var stats: StatisticsLogic {
        StatisticsLogic(items: historyStore.items)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Statistics")
                    .font(.title2)
                    .fontDesign(.rounded)
                    .padding(.bottom, 4)

                if historyStore.items.isEmpty {
                    ContentUnavailableView("No Data Yet", systemImage: "chart.bar")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    overviewSection
                        .padding(.bottom, 4)
                    performanceSection
                        .padding(.bottom, 4)
                    settingsSection
                        .padding(.bottom, 4)
                    timerSection
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

    private var overviewSection: some View {
        GroupBox(localized("Overview")) {
            statisticRow(localized("Total games"), value: "\(stats.totalGames)")
            statisticRow(localized("Wins"), value: "\(stats.wonGames)")
            statisticRow(localized("Losses"), value: "\(stats.lostGames)")
            statisticRow(localized("Win rate"), value: "\(formatted(stats.winRate, decimals: 1))%")
        }
    }

    private var performanceSection: some View {
        GroupBox(localized("Performance")) {
            statisticRow(localized("Total score"), value: "\(stats.totalScore)")
            statisticRow(localized("Average score"), value: formatted(stats.averageScore, decimals: 1))
            statisticRow(localized("Average steps"), value: formatted(stats.averageSteps, decimals: 2))
            statisticRow(localized("Average step ratio"), value: formatted(stats.averageStepRatio, decimals: 2))
        }
    }
    
    private var timerSection: some View {
        GroupBox(localized("Timing")) {
            // GameLogic.formatDuration(TimeInterval(stats.averageDuration))

            statisticRow(localized("Average game duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageDuration)))")
            statisticRow(localized("Average won game duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageDurationForWonGames)))")
            statisticRow(localized("Average guess duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageStepDuration)))")
            statisticRow(localized("Average won game guess duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageStepDurationForWonGames)))")
            
        }
    }

    private var settingsSection: some View {
        GroupBox(localized("Most Used Settings")) {
            statisticRow(localized("Mode"), value: localizedMode(stats.mostUsedMode))
            statisticRow(localized("Answer length"), value: localizedLength(stats.mostUsedLength))
            statisticRow(localized("Repeats"), value: localizedRepeats(stats.mostUsedRepeats))
            statisticRow(localized("Timing"), value: localizedTimers(stats.mostUsedTimers))
        }
    }

    // MARK: - Localized Helpers

    private func localizedMode(_ result: StatisticsLogic.ModeResult) -> String {
        switch result {
        case .hard: return localized("Hard")
        case .normal: return localized("Normal")
        case .tie: return localized("Tie")
        case .none: return localized("-")
        }
    }

    private func localizedLength(_ length: Int?) -> String {
        guard let length = length else { return localized("-") }
        return localized("%lld digits", length)
    }

    private func localizedRepeats(_ result: StatisticsLogic.mostUsedRepeatsResult) -> String {
        switch result {
        case .on: return localized("Repeats On")
        case .off: return localized("Repeats Off")
        case .tie: return localized("Tie")
        case .none: return localized("-")
        }
    }
    
    private func localizedTimers(_ result: StatisticsLogic.mostUsedTimerResult) -> String {
        switch result {
        case .all: return localized("Timers are on")
        case .perGuess: return localized("Per guess timer is on")
        case .perGame: return localized("Per game timer is on")
        case .off: return localized("Timers are off")
        case .none: return localized("-")
        }
    }

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

