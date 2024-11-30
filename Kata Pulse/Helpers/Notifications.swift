//
//  Notifications.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 11/27/24.
//

import Foundation

extension Notification.Name {
    static let nextMoveReceived = Notification.Name("nextMoveReceived")
    static let watchCommandRecieved = Notification.Name("WatchCommandReceived")
    static let motionUpdate = Notification.Name("MotionUpdate")

}
