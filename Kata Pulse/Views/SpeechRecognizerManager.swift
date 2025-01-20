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
    private let audioEngine = AVAudioEngine()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?

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

    func startListening(matching techniques: [String]) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer is not available.")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated successfully.")
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            print("Invalid recording format: No channels available.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized text: \(self.recognizedText)")

                    if techniques.contains(self.recognizedText) {
                        print("Matched technique: \(self.recognizedText)")
                        self.stopListening()
                        self.onMatch?(self.recognizedText)
                    }
                }
            }
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopListening()
            }
        }

        isListening = true
    }


    func stopListening() {
        // Stop the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stop the audio engine and remove the tap
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.reset()

        // Update listening state
        isListening = false
    }

}
