//
//  StatisticsTab.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct StatisticsTab: View {
    var body: some View {
        NavigationView {
            CountingStatisticsView()
                .navigationTitle("Statistics")
        }
    }
}
