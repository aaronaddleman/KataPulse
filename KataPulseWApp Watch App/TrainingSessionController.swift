//
//  TrainingSessionController.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 11/4/24.
//

import WatchKit
import WatchConnectivity

class TrainingSessionController: WKInterfaceController, WKExtendedRuntimeSessionDelegate, WCSessionDelegate {
    var extendedRuntimeSession: WKExtendedRuntimeSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func startExtendedSession() {
        extendedRuntimeSession = WKExtendedRuntimeSession()
        extendedRuntimeSession?.delegate = self
        extendedRuntimeSession?.start()
    }

    func endExtendedSession() {
        extendedRuntimeSession?.invalidate()
        extendedRuntimeSession = nil
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) { }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) { }

    func extendedRuntimeSessionDidInvalidate(_ extendedRuntimeSession: WKExtendedRuntimeSession) { }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) { }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message["command"] as? String {
            if command == "startTraining" {
                startExtendedSession()
            } else if command == "endTraining" {
                endExtendedSession()
            }
        }
    }
}
