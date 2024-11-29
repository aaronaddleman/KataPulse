//
//  WatchManager+iOS.swift
//  Kata Pulse
//


#if os(iOS)
import WatchConnectivity

extension WatchManager {
    
    public func sessionDidDeactivate(_ session: WCSession) {
        logger.log("Session deactivated. Reactivating...")
        WCSession.default.activate()
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
        logger.log("Session became inactive.")
    }

    func sendMessageToWatch(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            logger.log("Watch is not reachable.")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            self.logger.log("Failed to send message to Watch: \(error.localizedDescription)")
        }
    }

    func sendStartTrainingMessage() {
        print("sendStartTrainingMessage")
        sendMessageToWatch(["command": "startTraining"])
    }

    func sendEndTrainingMessage() {
        print("sendEndTrainingMessage)")
        sendMessageToWatch(["command": "endTraining"])
    }
}
#endif
