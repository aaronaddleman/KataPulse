//
//  WatchManager.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/27/24.
//

import WatchConnectivity
import SwiftUI
import CoreMotion
import os.log

public class WatchManager: NSObject, ObservableObject, WCSessionDelegate {
    // Singleton instance
    public static let shared = WatchManager()

    // Shared properties
    internal let logger = Logger(subsystem: "com.example.KataPulse", category: "WatchManager") // Internal for extensions
    internal let motionManager = CMMotionManager()
    public var gestureThreshold: Double = 2.0 // Sensitivity threshold
    private var isDetectingGesture = false
    #if os(watchOS)
    internal var extendedRuntimeSession: WKExtendedRuntimeSession?
    #endif
    
    internal var countdownTimer: Timer? // Timer for countdown
    internal var countdown = 5 // Initial countdown value
    internal var isMoving = false // Tracks whether the watch is in motion
    
    internal var countdownValue: Int = 5


    // MARK: - Initializer
    override private init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("WCSession activated with state: \(session.activationState.rawValue)")
        } else {
            print("WCSession is not supported on this device")
        }
    }
    
    public func startSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState != .activated {
                session.delegate = self
                session.activate()
                logger.log("WCSession activated.")
            } else {
                logger.log("WCSession is already active.")
            }
        } else {
            logger.log("WCSession is not supported on this device.")
        }
    }

    // MARK: - Gesture Detection
    public func startGestureDetection(onMotionDetected: @escaping (Double) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            logger.log("Device motion not available.")
            return
        }
        logger.log("Starting gesture detection.")

        motionManager.deviceMotionUpdateInterval = 0.05 // 20Hz sampling rate
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            let magnitude = sqrt(
                pow(motion.userAcceleration.x, 2) +
                pow(motion.userAcceleration.y, 2) +
                pow(motion.userAcceleration.z, 2)
            )
            onMotionDetected(magnitude) // Update the progress bar in ContentView
        }
    }


    public func stopGestureDetection() {
        logger.log("Stopping gesture detection.")
        isDetectingGesture = false
        motionManager.stopDeviceMotionUpdates()
    }

    internal func handleDeviceMotion(_ motion: CMDeviceMotion) {
        // Calculate motion magnitude
        let magnitude = sqrt(
            pow(motion.userAcceleration.x, 2) +
            pow(motion.userAcceleration.y, 2) +
            pow(motion.userAcceleration.z, 2)
        )

        logger.log("Motion magnitude: \(magnitude)")

        if magnitude > gestureThreshold {
            logger.log("Motion detected. Resetting countdown.")
            
            // Motion detected: Reset countdown and stop the current timer
            countdownTimer?.invalidate()
            countdownValue = 5
        } else if countdownTimer == nil {
            // If no motion is detected and no timer is running, start the countdown
            startCountdown()
        }
    }

    
    func startCountdown() {
        logger.log("Starting countdown: \(self.countdownValue) seconds")
        countdownValue = 5
        countdownTimer?.invalidate() // Ensure no duplicate timers

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return } // Prevent retain cycles
            if self.countdownValue > 0 {
                self.logger.log("Countdown: \(self.countdownValue)")
                #if os(watchOS)
                WKInterfaceDevice.current().play(.click) // Haptic feedback
                #endif
                self.countdownValue -= 1
            } else {
                self.logger.log("Countdown complete. Moving to next step.")
                self.countdownTimer?.invalidate()
                self.advanceToNextStep() // Notify to move to the next step
            }
        }
    }

    
    func stopCountdown() {
        logger.log("Stopping countdown.")
        countdownTimer?.invalidate()
        countdownValue = 5 // Reset countdown value
    }

    private func advanceToNextStep() {
        NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
    }


    // MARK: - Messaging
    public func sendProgressUpdate(message: String) {
        if WCSession.default.isReachable {
            let progressMessage = ["progressUpdate": message]
            WCSession.default.sendMessage(progressMessage, replyHandler: nil) { error in
                self.logger.log("Error sending progress update: \(error.localizedDescription)")
            }
        } else {
            logger.log("Device is not reachable.")
        }
    }

    // MARK: - WCSessionDelegate Methods
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.log("WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.log("WCSession activated with state: \(activationState.rawValue).")
        }
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("function: didReceiveMessage")
        if let command = message["command"] as? String {
            DispatchQueue.main.async {
                self.handleReceivedCommand(command)
            }
        }
    }

    private func handleReceivedCommand(_ command: String) {
        switch command {
        case "nextMove":
            NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
        case "startTraining":
            startGestureDetection { magnitude in
                // Handle the motion magnitude update here
                print("Motion magnitude: \(magnitude)")
                // Example: Post a notification or update the UI
                NotificationCenter.default.post(name: .motionUpdate, object: magnitude)
            }        case "endTraining":
            stopGestureDetection()
        default:
            logger.log("Unknown command received: \(command)")
        }
    }
}
