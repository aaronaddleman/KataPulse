//
//  ContentView.swift
//  KataPulseWApp Watch App
//
//  Created by Aaron Addleman on 10/27/24.
//

import SwiftUI
import Foundation
import WatchConnectivity
import os.log
import WatchKit // Needed for haptic feedback

struct ContentView: View {
    @State private var motionProgress: Double = 0.0
    @State private var countdown: Int = 5
    @State private var sensitivity: Double = 2.0
    @State private var gestureDetectionActive: Bool = false
    @State private var smoothedMotionProgress: Double = 0.0
    @State private var currentStepName: String = "Ready" // Holds the current step name

    private let logger = Logger(subsystem: "com.example.KataPulse", category: "Watch")

    var body: some View {
        TabView {
            // Page 1: Manual Advancement
            VStack {

                Text(currentStepName) // Displays the current step name or "Session Complete!"
                    .font(.headline)
                    .foregroundColor(currentStepName == "Session Complete!" ? .green : .blue) // Highlight session completion
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 15)

                if currentStepName != "Session Complete!" {
                    Button("Goto Next Step") {
                        logger.log("Next Step button pressed.")
                        if WCSession.default.isReachable {
                            WCSession.default.sendMessage(["command": "nextMove"], replyHandler: nil) { error in
                                logger.error("Failed to send nextMove command: \(error.localizedDescription)")
                            }
                        } else {
                            logger.log("iPhone is not reachable.")
                        }
                        NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Text("Training session is complete. Great job!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
            }
            .tabItem {
                Label("Manual", systemImage: "hand.point.right")
            }

            // Page 2: Detection Features
            ScrollView {
                VStack {
                    Text("Motion Detection")
                        .font(.headline)
                        .padding()

                    ProgressView(value: motionProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(5)
                        .padding()

                    Text("Countdown: \(countdown)")
                        .font(.subheadline)
                        .padding()

                    VStack {
                        Text("Sensitivity: \(String(format: "%.1f", sensitivity))")
                            .font(.caption)

                        Slider(value: $sensitivity, in: 0.5...5.0, step: 0.1)
                            .padding()
                            .onChange(of: sensitivity) { oldValue, newValue in
                                WatchManager.shared.gestureThreshold = newValue
                            }
                    }

                    Button(gestureDetectionActive ? "Stop Gesture Detection" : "Start Gesture Detection") {
                        if gestureDetectionActive {
                            WatchManager.shared.stopGestureDetection()
                            gestureDetectionActive = false
                        } else {
                            WatchManager.shared.startGestureDetection { magnitude in
                                updateMotionProgress(magnitude)
                            }
                            gestureDetectionActive = true
                        }
                    }
                    .padding()
                    .background(gestureDetectionActive ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .tabItem {
                Label("Detection", systemImage: "waveform.path.ecg")
            }
        }
        .tabViewStyle(PageTabViewStyle()) // Enable swipe between pages
        .indexViewStyle(PageIndexViewStyle()) // Optional dots indicator
        .onAppear {
            resetVisualState()
            WatchManager.shared.activateSession()
            subscribeToStepUpdates() // Subscribe to step name and session finished updates
            requestNotificationPermissions() // (Optional) Request permissions for local notifications
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .stepNameUpdated, object: nil)
            NotificationCenter.default.removeObserver(self, name: .sessionFinished, object: nil)
        }
    }

    // Function to update motion progress with smoothing
    private func updateMotionProgress(_ magnitude: Double) {
        let smoothingFactor = 0.2 // Controls how smooth the transition is (0.0 - no change, 1.0 - immediate change)
        
        // Apply exponential smoothing
        let newSmoothedValue = smoothingFactor * magnitude + (1 - smoothingFactor) * smoothedMotionProgress
        smoothedMotionProgress = newSmoothedValue // Update the @State property
        
        // Normalize the smoothed value to map it to the progress bar range
        let normalizedMagnitude = min(max(smoothedMotionProgress / WatchManager.shared.gestureThreshold, 0.0), 1.0)
        motionProgress = normalizedMagnitude

        // Handle countdown logic
        if normalizedMagnitude < 0.25 { // Inside green zone
            if countdown > 0 {
                countdown -= 1
            } else {
                NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
                resetVisualState()
            }
        } else {
            resetCountdown()
        }
    }

    private func resetCountdown() {
        countdown = 5
    }

    private func resetVisualState() {
        motionProgress = 0.0
        countdown = 5
    }

    // Function to subscribe to notifications
    private func subscribeToStepUpdates() {
        // Subscribe to step name updates
        NotificationCenter.default.addObserver(forName: .stepNameUpdated, object: nil, queue: .main) { notification in
            if let stepName = notification.object as? String {
                self.currentStepName = stepName // Update the displayed step name
            }
        }
        
        // Subscribe to session finished updates
        NotificationCenter.default.addObserver(forName: .sessionFinished, object: nil, queue: .main) { _ in
            self.currentStepName = "Session Complete!"
            // Optionally, trigger haptic feedback
            WKInterfaceDevice.current().play(.success)
            // Optionally, trigger a local notification
            // sendLocalNotification()
        }
    }
    
    // MARK: - (Optional) Local Notifications
    
    private func requestNotificationPermissions() {
        // Only necessary if implementing local notifications
        // Uncomment the following lines if you want to enable local notifications
        
        /*
        import UserNotifications
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                logger.log("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
        */
    }
    
    private func sendLocalNotification() {
        // Only necessary if implementing local notifications
        // Uncomment the following lines if you want to enable local notifications
        
        /*
        import UserNotifications
        
        let content = UNMutableNotificationContent()
        content.title = "Training Session"
        content.body = "Your training session has ended."
        let request = UNNotificationRequest(identifier: "TrainingEnded", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        */
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
