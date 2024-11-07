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

class WatchManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchManager() // Singleton instance
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "WatchManager")

    private let motionManager = CMMotionManager()
    private var gestureThreshold: Double = 2.0 // Sensitivity threshold
    private var isDetectingGesture = false

    #if os(watchOS)
    private var hapticFeedback: WKInterfaceDevice { WKInterfaceDevice.current() }
    #endif

    override init() {
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

    // MARK: - Starting the Session
    func startSession() {
        print("Starting watch session...")
        if WCSession.default.activationState == .activated {
            logger.log("Session is already active.")
        } else {
            WCSession.default.activate()
        }
    }

    // MARK: - Gesture Detection
    func startGestureDetection() {
        guard motionManager.isDeviceMotionAvailable else {
            logger.log("Device motion not available.")
            return
        }
        logger.log("Starting gesture detection.")
        isDetectingGesture = true

        motionManager.deviceMotionUpdateInterval = 0.05 // 20Hz sampling rate
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.handleDeviceMotion(motion)
        }
    }

    func stopGestureDetection() {
        logger.log("Stopping gesture detection.")
        isDetectingGesture = false
        motionManager.stopDeviceMotionUpdates()

        #if os(watchOS)
        hapticFeedback.play(.notification) // Feedback on stopping detection
        #endif
    }

    private func handleDeviceMotion(_ motion: CMDeviceMotion) {
        let magnitude = sqrt(
            pow(motion.userAcceleration.x, 2) +
            pow(motion.userAcceleration.y, 2) +
            pow(motion.userAcceleration.z, 2)
        )

        logger.log("Motion magnitude: \(magnitude)")

        if magnitude > gestureThreshold && isDetectingGesture {
            logger.log("Gesture detected! Triggering next move.")
            #if os(watchOS)
            hapticFeedback.play(.success) // Haptic feedback on success
            #endif
            NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
        }
    }
    
    func sendProgressUpdate(message: String) {
        if WCSession.default.isReachable {
            let progressMessage = ["progressUpdate": message]
            WCSession.default.sendMessage(progressMessage, replyHandler: nil) { error in
                print("Error sending progress update: \(error.localizedDescription)")
            }
            print("Sending progress update: \(message)")
        } else {
            print("iPhone is not reachable.")
        }
    }

    // MARK: - Sending and Receiving Messages
    func sendMessageToWatch(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            logger.log("Watch is not reachable.")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            self.logger.log("Failed to send message to Watch: \(error.localizedDescription)")
        }
    }

    func sendMessageToiPhone(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            logger.log("iPhone is not reachable.")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            self.logger.log("Failed to send message to iPhone: \(error.localizedDescription)")
        }
    }

    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.log("WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.log("WCSession activated with state: \(activationState.rawValue).")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
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
            startGestureDetection()
        case "endTraining":
            stopGestureDetection()
        default:
            logger.log("Unknown command received: \(command)")
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        logger.log("Received user info: \(userInfo)")
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        logger.log("Received file: \(file.fileURL)")
    }

    // MARK: - Handling Session State Changes (iOS only)
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        logger.log("Session deactivated. Reactivating...")
        WCSession.default.activate()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.log("Session became inactive.")
    }
    #endif
    
    func sendStartTrainingMessage() {
        sendMessageToWatch(["command": "startTraining"])
    }

    func sendEndTrainingMessage() {
        sendMessageToWatch(["command": "endTraining"])
    }

}

// MARK: - Notification Extension
extension Notification.Name {
    static let nextMoveReceived = Notification.Name("NextMoveReceived")
}

