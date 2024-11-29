//
//  WatchManager+watchOS.swift
//  Kata Pulse
//

#if os(watchOS)
import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion

private var isMoving = false
private var countdownTimer: Timer?
private var countdown = 5

extension WatchManager: WKExtendedRuntimeSessionDelegate {
    
    public func startMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else {
            logger.log("Motion detection is not available.")
            return
        }

        logger.log("Starting motion detection.")
        motionManager.deviceMotionUpdateInterval = 0.05 // 20 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.handleDeviceMotion(motion)
        }
    }

    func stopMotionDetection() {
        motionManager.stopDeviceMotionUpdates() // Stop monitoring device motion
        countdownTimer?.invalidate() // Stop any ongoing countdown
        countdownValue = 5 // Reset the countdown value
        logger.log("Motion detection stopped.")
    }
    
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
