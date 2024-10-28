//
//  WatchManager.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/27/24.
//

import WatchConnectivity
import SwiftUI
import os.log

class WatchManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchManager() // Singleton instance
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "WatchManager")

    // Make the initializer internal (instead of private) for use within the module
    override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
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
    }

    // Handle messages received from the other device
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message["command"] as? String {
            DispatchQueue.main.async {
                self.handleReceivedCommand(command)
            }
        }
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
}
