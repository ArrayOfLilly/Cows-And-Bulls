//
//  StatisticSupportViews.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct StatisticContentView: View {
    let stats: StatisticsLogic
    let isHistoryModified: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatisticTitleView()

            if isHistoryModified {
                StatisticWarningView()
            }

            StatisticOverviewSection(stats: stats)
                .padding(.bottom, 4)
            StatisticPerformanceSection(stats: stats)
                .padding(.bottom, 4)
            StatisticMostUsedSection(stats: stats)
                .padding(.bottom, 4)
            StatisticTimingSection(stats: stats)
        }
    }
}

struct StatisticTitleView: View {
    var body: some View {
        Text(localized("stats.title"))
            .font(.title2)
            .fontDesign(.rounded)
            .padding(.bottom, 4)
    }
}

struct StatisticWarningView: View {
    var body: some View {
        Text(localized("stats.warning.modified"))
            .font(.caption)
            .foregroundStyle(.yellow)
            .padding(.bottom, 4)
    }
}

struct StatisticOverviewSection: View {
    let stats: StatisticsLogic

    var body: some View {
        GroupBox(localized("stats.section.overview")) {
            StatisticRow(title: localized("stats.row.total_games"), value: "\(stats.totalGames)")
            StatisticRow(title: localized("stats.row.wins"), value: "\(stats.wonGames)")
            StatisticRow(title: localized("stats.row.losses"), value: "\(stats.lostGames)")
            StatisticRow(title: localized("stats.row.win_rate"), value: "\(StatisticFormatters.decimal(stats.winRate, decimals: 1))%")
            StatisticRow(title: localized("stats.row.first_guess_wins"), value: "\(stats.firstGuessWinsCount)")
            StatisticRow(title: localized("stats.row.first_guess_win_rate"), value: "\(StatisticFormatters.decimal(stats.firstGuessWinRate, decimals: 1))%")
        }
    }
}

struct StatisticPerformanceSection: View {
    let stats: StatisticsLogic

    var body: some View {
        GroupBox(localized("stats.section.performance")) {
            StatisticRow(title: localized("stats.row.total_score"), value: "\(stats.totalScore)")
            StatisticRow(title: localized("stats.row.best_score"), value: "\(stats.bestScore)")
            StatisticRow(title: localized("stats.row.average_score"), value: StatisticFormatters.decimal(stats.averageScore, decimals: 1))
            StatisticRow(title: localized("stats.row.average_steps"), value: StatisticFormatters.decimal(stats.averageSteps, decimals: 2))
            StatisticRow(title: localized("stats.row.average_step_ratio"), value: StatisticFormatters.decimal(stats.averageStepRatio, decimals: 2))
        }
    }
}

struct StatisticTimingSection: View {
    let stats: StatisticsLogic

    var body: some View {
        GroupBox(localized("stats.section.timing")) {
            StatisticRow(title: localized("stats.row.average_game_duration"), value: GameLogic.formatDuration(TimeInterval(stats.averageDuration)))
            StatisticRow(title: localized("stats.row.average_won_game_duration"), value: GameLogic.formatDuration(TimeInterval(stats.averageDurationForWonGames)))
            StatisticRow(title: localized("stats.row.average_guess_duration"), value: GameLogic.formatDuration(TimeInterval(stats.averageStepDuration)))
            StatisticRow(title: localized("stats.row.average_won_guess_duration"), value: GameLogic.formatDuration(TimeInterval(stats.averageStepDurationForWonGames)))
            StatisticRow(title: localized("stats.row.timeout_losses"), value: "\(stats.timeoutLossesCount)")
            StatisticRow(title: localized("stats.row.timeout_rate"), value: "\(StatisticFormatters.decimal(stats.timeoutRate, decimals: 1))%")
        }
    }
}

struct StatisticMostUsedSection: View {
    let stats: StatisticsLogic

    var body: some View {
        GroupBox(localized("stats.section.most_used")) {
            StatisticRow(title: localized("stats.row.mode"), value: StatisticFormatters.localizedMode(stats.mostUsedMode))
            StatisticRow(title: localized("stats.row.answer_length"), value: StatisticFormatters.localizedLength(stats.mostUsedLength))
            StatisticRow(title: localized("stats.row.repeats"), value: StatisticFormatters.localizedRepeats(stats.mostUsedRepeats))
            StatisticRow(title: localized("stats.row.timing"), value: StatisticFormatters.localizedTimers(stats.mostUsedTimers))
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}

enum StatisticFormatters {
    static func localizedMode(_ result: StatisticsLogic.ModeResult) -> String {
        switch result {
        case .hard: return localized("stats.value.mode.hard")
        case .normal: return localized("stats.value.mode.normal")
        case .tie: return localized("stats.value.mode.tie")
        case .none: return localized("stats.value.none")
        }
    }

    static func localizedLength(_ length: Int?) -> String {
        guard let length else { return localized("stats.value.none") }
        return localized("stats.value.length.format", length)
    }

    static func localizedRepeats(_ result: StatisticsLogic.mostUsedRepeatsResult) -> String {
        switch result {
        case .on: return localized("stats.value.repeats.on")
        case .off: return localized("stats.value.repeats.off")
        case .tie: return localized("stats.value.mode.tie")
        case .none: return localized("stats.value.none")
        }
    }

    static func localizedTimers(_ result: StatisticsLogic.mostUsedTimerResult) -> String {
        switch result {
        case .all: return localized("stats.value.timers.all")
        case .perGuess: return localized("stats.value.timers.per_guess")
        case .perGame: return localized("stats.value.timers.per_game")
        case .off: return localized("stats.value.timers.off")
        case .none: return localized("stats.value.none")
        }
    }

    static func decimal(_ value: Double, decimals: Int) -> String {
        String(format: "%.*f", decimals, value)
    }
}
