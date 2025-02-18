//
//  BeltLevel.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 2/9/25.
//

import SwiftUI

protocol BeltLevelItem {
    var beltLevel: BeltLevel { get }
}

enum BeltLevel: String, CaseIterable, Codable {
    case white = "White"
    case yellow = "Yellow"
    case orange = "Orange"
    case green = "Green"
    case blue = "Blue"
    case brown = "Brown"
    case black = "Black"
    case unknown = "Unknown" // Default case

    var backgroundColor: Color {
        switch self {
        case .white: return Color.clear
        case .yellow: return Color.yellow.opacity(0.3)
        case .orange: return Color.orange.opacity(0.3)
        case .green: return Color.green.opacity(0.3)
        case .blue: return Color.blue.opacity(0.3)
        case .brown: return Color.brown.opacity(0.3)
        case .black: return Color.black.opacity(0.7)
        case .unknown: return Color.gray.opacity(0.3)
        }
    }
}
