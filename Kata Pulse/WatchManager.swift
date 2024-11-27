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
    private let motionManager = CMMotionManager()
    private var gestureThreshold: Double = 2.0 // Sensitivity threshold
    private var isDetectingGesture = false
    #if os(watchOS)
    internal var extendedRuntimeSession: WKExtendedRuntimeSession?
    #endif

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
    public func startGestureDetection() {
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

    public func stopGestureDetection() {
        logger.log("Stopping gesture detection.")
        isDetectingGesture = false
        motionManager.stopDeviceMotionUpdates()
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
            NotificationCenter.default.post(name: .nextMoveReceived, object: nil)
        }
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
}

// MARK: - Notification Extension
extension Notification.Name {
    static let nextMoveReceived = Notification.Name("NextMoveReceived")
}
