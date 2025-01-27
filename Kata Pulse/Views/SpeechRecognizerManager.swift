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
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    @Published var isListening: Bool = false


    var isAudioEngineRunning: Bool {
        audioEngine.isRunning
    }

    func startListening(onResult: @escaping (String, Bool) -> Void) {
        // Check if the audio engine is already running
        guard !audioEngine.isRunning else {
            print("Audio engine is already running.")
            return
        }

        // Ensure the previous recognition task is finished
        recognitionTask?.cancel()
        recognitionTask = nil

        // Clear recognized text and set isListening
        recognizedText = ""
        isListening = true

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated successfully.")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            return
        }

        // Set up recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        // Ensure no previous taps are installed
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Install a new tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("Audio engine started.")
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            stopListening()
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let isFinal = result.isFinal
                let transcription = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    self.recognizedText = transcription
                    onResult(transcription, isFinal)
                }

                // Stop listening automatically if the result is final
                if isFinal {
                    self.stopListening()
                }
            }

            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopListening()
            }
        }
    }


    func stopListening(onStop: ((String) -> Void)? = nil) {
        guard audioEngine.isRunning else {
            print("Audio engine is not running.")
            return
        }

        isListening = false

        // Stop the recognition task and audio engine
        recognitionTask?.finish() // Ensure the task finishes gracefully
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated.")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }

        // Trigger evaluation of the last recognized text
        if !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onStop?(recognizedText)
        } else {
            print("No recognized text to evaluate.")
        }
    }

}
