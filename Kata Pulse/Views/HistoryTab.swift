//
//  HistoryTab.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct HistoryTab: View {
    var body: some View {
        NavigationView {
            TrainingSessionHistoryView()
                .navigationTitle("Training History")
        }
    }
}
