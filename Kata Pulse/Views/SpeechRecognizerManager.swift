//
//  SpeechRecognizerManager.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import Speech
import AVFoundation

class SpeechRecognizerManager: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isListening: Bool = false

    private let speechRecognizer = SFSpeechRecognizer()
    var audioEngine = AVAudioEngine()
    var recognitionTask: SFSpeechRecognitionTask?

    var onMatch: ((String) -> Void)?

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    print("Speech recognition authorization denied.")
                }
            }
        }
    }

    func startListening(matching phrases: [String], onResult: @escaping (String) -> Void) {
        self.onMatch = onResult

        // Ensure the recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer is not available.")
            return
        }

        // Check if audio session or engine is already active
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isOtherAudioPlaying || audioEngine.isRunning {
            print("Audio session is already active.")
            return
        }

        // Configure audio session
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated successfully.")
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
            return
        }

        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stop the audio engine if needed
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Create a new recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            print("Invalid recording format: No channels available.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            return
        }

        // Start the recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.restartListening() // Automatically restart listening
                return
            }

            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized text: \(self.recognizedText)")
                    self.onMatch?(self.recognizedText)
                }
            }
        }

        isListening = true
    }


    func stopListening() {
        print("Stopping recognition task...")
        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            print("Stopping audio engine...")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false
        print("Stopped listening.")
    }

    func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startListening(matching: [], onResult: self.onMatch ?? { _ in })
        }
    }

}
