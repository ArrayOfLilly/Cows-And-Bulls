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
        // Keep derivation local and always based on current history snapshot.
        StatisticsLogic(items: historyStore.items)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(localized("stats.title"))
                    .font(.title2)
                    .fontDesign(.rounded)
                    .padding(.bottom, 4)

                if historyStore.items.isEmpty {
                    ContentUnavailableView(localized("history.empty.title"), systemImage: "chart.bar")
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
        .navigationTitle(localized("stats.title"))
        .frame(maxWidth: .infinity)
        .frame(minHeight: 350, maxHeight: .infinity)
        .tabItem {
            Label(localized("tab.stats"), systemImage: "chart.xyaxis.line")
        }
    }

    private var overviewSection: some View {
        GroupBox(localized("stats.section.overview")) {
            statisticRow(localized("stats.row.total_games"), value: "\(stats.totalGames)")
            statisticRow(localized("stats.row.wins"), value: "\(stats.wonGames)")
            statisticRow(localized("stats.row.losses"), value: "\(stats.lostGames)")
            statisticRow(localized("stats.row.win_rate"), value: "\(formatted(stats.winRate, decimals: 1))%")
            statisticRow(localized("stats.row.first_guess_wins"), value: "\(stats.firstGuessWinsCount)")
            statisticRow(localized("stats.row.first_guess_win_rate"), value: "\(formatted(stats.firstGuessWinRate, decimals: 1))%")
        }
    }

    private var performanceSection: some View {
        GroupBox(localized("stats.section.performance")) {
            statisticRow(localized("stats.row.total_score"), value: "\(stats.totalScore)")
            statisticRow(localized("stats.row.best_score"), value: "\(stats.bestScore)")
            statisticRow(localized("stats.row.average_score"), value: formatted(stats.averageScore, decimals: 1))
            statisticRow(localized("stats.row.average_steps"), value: formatted(stats.averageSteps, decimals: 2))
            statisticRow(localized("stats.row.average_step_ratio"), value: formatted(stats.averageStepRatio, decimals: 2))
        }
    }
    
    private var timerSection: some View {
        GroupBox(localized("stats.section.timing")) {
            // GameLogic.formatDuration(TimeInterval(stats.averageDuration))

            statisticRow(localized("stats.row.average_game_duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageDuration)))")
            statisticRow(localized("stats.row.average_won_game_duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageDurationForWonGames)))")
            statisticRow(localized("stats.row.average_guess_duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageStepDuration)))")
            statisticRow(localized("stats.row.average_won_guess_duration"), value: "\(GameLogic.formatDuration(TimeInterval(stats.averageStepDurationForWonGames)))")
            statisticRow(localized("stats.row.timeout_losses"), value: "\(stats.timeoutLossesCount)")
            statisticRow(localized("stats.row.timeout_rate"), value: "\(formatted(stats.timeoutRate, decimals: 1))%")
            
        }
    }

    private var settingsSection: some View {
        GroupBox(localized("stats.section.most_used")) {
            statisticRow(localized("stats.row.mode"), value: localizedMode(stats.mostUsedMode))
            statisticRow(localized("stats.row.answer_length"), value: localizedLength(stats.mostUsedLength))
            statisticRow(localized("stats.row.repeats"), value: localizedRepeats(stats.mostUsedRepeats))
            statisticRow(localized("stats.row.timing"), value: localizedTimers(stats.mostUsedTimers))
        }
    }

    // MARK: - Localized Helpers

    private func localizedMode(_ result: StatisticsLogic.ModeResult) -> String {
        switch result {
        case .hard: return localized("stats.value.mode.hard")
        case .normal: return localized("stats.value.mode.normal")
        case .tie: return localized("stats.value.mode.tie")
        case .none: return localized("stats.value.none")
        }
    }

    private func localizedLength(_ length: Int?) -> String {
        guard let length = length else { return localized("stats.value.none") }
        return localized("stats.value.length.format", length)
    }

    private func localizedRepeats(_ result: StatisticsLogic.mostUsedRepeatsResult) -> String {
        switch result {
        case .on: return localized("stats.value.repeats.on")
        case .off: return localized("stats.value.repeats.off")
        case .tie: return localized("stats.value.mode.tie")
        case .none: return localized("stats.value.none")
        }
    }
    
    private func localizedTimers(_ result: StatisticsLogic.mostUsedTimerResult) -> String {
        switch result {
        case .all: return localized("stats.value.timers.all")
        case .perGuess: return localized("stats.value.timers.per_guess")
        case .perGame: return localized("stats.value.timers.per_game")
        case .off: return localized("stats.value.timers.off")
        case .none: return localized("stats.value.none")
        }
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        // Fixed decimals keeps row layout stable and easier to scan.
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
