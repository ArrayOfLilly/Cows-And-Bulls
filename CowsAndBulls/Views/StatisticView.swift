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
                if historyStore.items.isEmpty {
                    ContentUnavailableView(localized("history.empty.title"), systemImage: "chart.bar")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    StatisticContentView(
                        stats: stats,
                        isHistoryModified: historyStore.isHistoryModified
                    )
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
}
