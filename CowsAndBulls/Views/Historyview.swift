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
    @EnvironmentObject private var settingsStore: ProfileSettingsStore
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
            HistoryControlsRow(filter: $filter, sort: $sort)

            HistoryContentView(
                allItems: historyStore.items,
                displayedItems: displayedItems,
                bullAssetName: settingsStore.settings.selectedBullAssetName,
                cowAssetName: settingsStore.settings.selectedCowAssetName,
                onDelete: historyStore.delete
            )
        }
        .toolbar {
            ToolbarItem(id: "Clear history", placement: .confirmationAction) {
                HistoryClearToolbarButton(
                    isDisabled: historyStore.items.isEmpty,
                    onTap: { showClearConfirmation = true }
                )
            }
        }
        .navigationTitle(localized("app.title"))
        .frame(maxWidth: .infinity)
        .frame(minHeight: 350, maxHeight: .infinity)
        .confirmationDialog(localized("history.clear.title"), isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button(localized("history.clear.action"), role: .destructive) {
                historyStore.clear()
            }
            Button(localized("common.action.cancel"), role: .cancel) {}
        } message: {
            Text(localized("history.clear.message"))
        }
        .tabItem {
            Label(localized("tab.history"), systemImage: "clock.arrow.circlepath")
        }
    }
}
