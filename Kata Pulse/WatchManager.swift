//
//  WatchManager.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/27/24.
//

import CoreMotion
import WatchConnectivity
import SwiftUI
import os.log
import Combine

class WatchManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchManager() // Singleton instance
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "WatchManager")
    private let motionManager = CMMotionManager() // For motion detection
    private var isDetectingMotion = false
    
    private var stillnessTimer: Timer? // Timer to track stillness
    public var gestureThreshold: Double = 2.0 // Sensitivity threshold
    private var isDetectingGesture = false
    #if os(watchOS)
    internal var extendedRuntimeSession: WKExtendedRuntimeSession?
    #endif
    
    internal var countdownTimer: Timer? // Timer for countdown
    internal var countdown = 5 // Initial countdown value
    internal var isMoving = false // Tracks whether the watch is in motion
    
    internal var countdownValue: Int = 5
    
    @Published var isReachable = false
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false

    // Make the initializer internal (instead of private) for use within the module
    override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func activateSession() {
        guard WCSession.isSupported() else {
            logger.error("WCSession is not supported on this device.")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        logger.log("WCSession activated on Apple Watch.")
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

    // MARK: - Sending Messages

    // Send a message to the Watch
    func sendMessageToWatch(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            logger.log("Watch is not reachable.")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            self.logger.log("Failed to send message to Watch: \(error.localizedDescription)")
        }
    }

    // Send a message to the iPhone (for watchOS app)
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

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            logger.log("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            logger.log("WCSession activated with state: \(activationState.rawValue).")
            
        }
        
        updateConnectivityStatus()
    }

    // Handle messages received from the other device
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message["command"] as? String {
            DispatchQueue.main.async {
                self.handleReceivedCommand(command)
                self.updateConnectivityStatus()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("refreshing updateConnectivityStatus")
            self.updateConnectivityStatus()
        }
    }
    
    public func updateConnectivityStatus() {
        let session = WCSession.default
        
        isReachable = session.isReachable // Available on both iOS and watchOS

        #if os(iOS)
        isPaired = session.isPaired // Only available on iOS
        isWatchAppInstalled = session.isWatchAppInstalled // Only available on iOS
        logger.log("Connectivity updated: Reachable - \(self.isReachable), Paired - \(self.isPaired), Installed - \(self.isWatchAppInstalled)")
        #elseif os(watchOS)
        logger.log("Connectivity updated: Reachable - \(self.isReachable). isPaired and isWatchAppInstalled are not applicable on watchOS.")
        #endif
    }

    // Handle commands received from the other device
    private func handleReceivedCommand(_ command: String) {
        switch command {
        case "nextMove":
            NotificationCenter.default.post(name: Notification.Name("NextMoveReceived"), object: nil)
        default:
            logger.log("Unknown command received: \(command)")
        }
    }

    // Handle transfer of user info
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        logger.log("Received user info: \(userInfo)")
    }

    // Handle received files
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
    
    func startGestureDetection(onMotionDetected: @escaping (Double) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            logger.log("Device motion is not available.")
            return
        }

        if isDetectingMotion {
            logger.log("Motion detection is already active.")
            return
        }

        logger.log("Starting gesture detection.")
        isDetectingMotion = true
        motionManager.deviceMotionUpdateInterval = 0.05 // Update rate (20Hz)
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            let magnitude = sqrt(
                pow(motion.userAcceleration.x, 2) +
                pow(motion.userAcceleration.y, 2) +
                pow(motion.userAcceleration.z, 2)
            )

            // Callback for visual feedback
            onMotionDetected(magnitude)

            // Handle stillness detection
            if magnitude < self.gestureThreshold {
                self.handleStillness()
            } else {
                self.resetStillnessTimer()
            }
        }
    }
    
    private func handleStillness() {
        if stillnessTimer == nil {
            logger.log("Stillness detected. Starting countdown.")
            countdownValue = 5 // Reset countdown
            stillnessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.countdownValue > 0 {
                    self.countdownValue -= 1
                    self.logger.log("Stillness countdown: \(self.countdownValue)")
                } else {
                    self.logger.log("Stillness confirmed. Moving to next step.")
                    self.notifyNextStep()
                    self.resetStillnessTimer()
                }
            }
        }
    }

    private func resetStillnessTimer() {
        logger.log("Motion detected. Resetting stillness timer.")
        stillnessTimer?.invalidate()
        stillnessTimer = nil
        countdownValue = 5 // Reset countdown
    }

    private func notifyNextStep() {
        NotificationCenter.default.post(name: Notification.Name("NextMoveReceived"), object: nil)
        logger.log("Next step notification posted.")
    }


    func stopGestureDetection() {
        guard isDetectingMotion else {
            logger.log("Motion detection is not active.")
            return
        }

        logger.log("Stopping gesture detection.")
        isDetectingMotion = false
        motionManager.stopDeviceMotionUpdates()
    }
    
    // Send progress updates between devices
    func sendProgressUpdate(message: String) {
        guard WCSession.default.isReachable else {
            logger.log("Device is not reachable.")
            return
        }

        let progressMessage = ["progressUpdate": message]
        WCSession.default.sendMessage(progressMessage, replyHandler: nil) { error in
            self.logger.log("Error sending progress update: \(error.localizedDescription)")
        }
    }

}
