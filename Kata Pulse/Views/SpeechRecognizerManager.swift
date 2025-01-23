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
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer is not available.")
            return
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated successfully.")
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
            return
        }

        // Reset existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Reset audio engine if needed
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Create a new request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.channelCount > 0 else {
            print("Invalid recording format: No channels available.")
            return
        }

        // Install tap to append audio buffers
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            print("Audio buffer received: \(buffer.frameLength) frames")
            request.append(buffer)
        }

        // Prepare and start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            return
        }

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.restartListening()
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
        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false
    }

    func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startListening(matching: [], onResult: self.onMatch ?? { _ in })
        }
    }
}
