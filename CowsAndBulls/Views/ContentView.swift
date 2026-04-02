//
//  ContentView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 24..
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GameRootView()
            HistoryView()
            StatisticView()
        }
        .frame(minWidth: 450, idealWidth: 450)
        .frame(minHeight: 600, idealHeight: 600)
    }
}
