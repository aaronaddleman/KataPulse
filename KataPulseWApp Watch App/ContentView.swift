//
//  ContentView.swift
//  KataPulseWApp Watch App
//
//  Created by Aaron Addleman on 10/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var gestureDetectionActive = false

    var body: some View {
        VStack {
            Text("Training Session")
                .font(.headline)

            Button("Next Step") {
                NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button(gestureDetectionActive ? "Stop Gesture Detection" : "Start Gesture Detection") {
                if gestureDetectionActive {
                    WatchManager.shared.stopGestureDetection()
                } else {
                    WatchManager.shared.startGestureDetection()
                }
                gestureDetectionActive.toggle()
            }
            .padding()
            .background(gestureDetectionActive ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            setupObservers()
        }
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(forName: .nextMoveReceived, object: nil, queue: .main) { _ in
            handleNextStep()
        }
    }

    private func handleNextStep() {
        print("Next step triggered.")
        WKInterfaceDevice.current().play(.success) // Haptic feedback on step completion
    }
}
