//
//  MotionValidationSettings.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/30/26.
//

import SwiftUI

/// Settings for motion validation features
struct MotionValidationSettings: View {
    @AppStorage("enableBlockMotionValidation") private var enableBlockMotionValidation = false
    @AppStorage("enableStrikeMotionValidation") private var enableStrikeMotionValidation = false
    @AppStorage("enableKickMotionValidation") private var enableKickMotionValidation = false
    @AppStorage("motionValidationStrictness") private var strictness: Double = 0.7
    
    var body: some View {
        Form {
            Section {
                Text("Use Apple Watch motion sensors to validate your movements during training.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Motion Validation", systemImage: "waveform.path")
            }
            
            Section {
                Toggle("Validate Blocks", isOn: $enableBlockMotionValidation)
                Toggle("Validate Strikes", isOn: $enableStrikeMotionValidation)
                Toggle("Validate Kicks", isOn: $enableKickMotionValidation)
            } header: {
                Text("Enable Validation For")
            } footer: {
                Text("When enabled, you must perform the correct movement to proceed to the next exercise.")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Strictness")
                        Spacer()
                        Text(strictnessLabel)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $strictness, in: 0.5...0.95, step: 0.05)
                        .tint(.blue)
                }
            } header: {
                Text("Validation Settings")
            } footer: {
                Text("Higher strictness requires more precise movements. Lower strictness is more forgiving for beginners.")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "Real-time Feedback",
                        description: "Get instant feedback on your form"
                    )
                    
                    FeatureRow(
                        icon: "waveform.path.ecg",
                        iconColor: .blue,
                        title: "Motion Analysis",
                        description: "Advanced motion pattern recognition"
                    )
                    
                    FeatureRow(
                        icon: "figure.martial.arts",
                        iconColor: .orange,
                        title: "Technique Improvement",
                        description: "Perfect your martial arts techniques"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("Features")
            }
        }
        .navigationTitle("Motion Validation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var strictnessLabel: String {
        switch strictness {
        case 0.5..<0.6:
            return "Very Lenient"
        case 0.6..<0.7:
            return "Lenient"
        case 0.7..<0.8:
            return "Moderate"
        case 0.8..<0.9:
            return "Strict"
        default:
            return "Very Strict"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MotionValidationSettings()
    }
}
