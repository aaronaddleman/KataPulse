//
//  WatchManager+watchOS.swift
//  Kata Pulse
//

#if os(watchOS)
import WatchKit
import Foundation
import WatchConnectivity

extension WatchManager: WKExtendedRuntimeSessionDelegate {
    public func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        logger.log("Extended runtime session started.")
    }

    public func endExtendedSession() {
        extendedRuntimeSession?.invalidate() // This will now resolve properly
        extendedRuntimeSession = nil
        logger.log("Extended runtime session ended.")
    }

    public func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        logger.log("Extended runtime session did start.")
    }

    public func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        logger.log("Extended runtime session will expire soon.")
    }

    public func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        if let error = error {
            logger.log("Extended runtime session invalidated with error: \(error.localizedDescription)")
        } else {
            logger.log("Extended runtime session invalidated with reason: \(reason.rawValue)")
        }
    }
}
#endif
