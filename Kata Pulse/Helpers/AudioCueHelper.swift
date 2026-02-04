//
//  AudioCueHelper.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import AVFoundation

struct AudioCueHelper {
    static let synthesizer = AVSpeechSynthesizer()

    public static func announce(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
