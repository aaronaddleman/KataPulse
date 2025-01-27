//
//  CalibrationView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/24/25.
//

import SwiftUI
import AVFoundation
import Speech
import CoreData
import os.log

public struct CalibrationView: View {
    @Environment(\.presentationMode) var presentationMode
    let session: TrainingSessionEntity
    @State private var techniques: [TechniqueEntity] = []
    @State private var currentTechniqueIndex: Int = 0
    @State private var isListening: Bool = false
    @State private var recognizedText: String = ""
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var shouldRestart: Bool = true
    @State private var showDeleteAllConfirmation = false


    private let logger = Logger(subsystem: "com.example.KataPulse", category: "CalibrationView")

    public init(session: TrainingSessionEntity) {
        self.session = session
    }

    public var body: some View {
        NavigationView {
            VStack {
                Text("Calibrating \(session.name ?? "Unnamed Session")")
                    .font(.title)
                    .padding()
                    .onAppear {
                        print("CalibrationView received session: \(session.name ?? "Unnamed Session")")
                    }

                Text("Techniques count: \(techniques.count)")
                    .padding()
                    .foregroundColor(.red) // Debugging view

                if techniques.isEmpty {
                    Text("No techniques selected")
                        .font(.title)
                        .padding()

                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                } else {
                    VStack {
                        Text(techniques[currentTechniqueIndex].name ?? "Unknown Technique")
                            .font(.title)
                            .padding()

                        Text("Recognized: \(recognizedText)")
                                .font(.body)
                                .padding()
                                .foregroundColor(.blue)

                        if let aliasesData = techniques[currentTechniqueIndex].aliases,
                           let aliases = try? JSONDecoder().decode([String].self, from: aliasesData) {
                            Text("Aliases:")
                                .font(.headline)
                                .padding(.top)

                            ForEach(Array(aliases.enumerated()), id: \.offset) { index, alias in
                                Text(alias)
                                    .font(.body)
                                    .padding(.bottom, 2)
                            }
                        } else {
                            Text("No aliases saved yet.")
                                .foregroundColor(.gray)
                        }


                        HStack {
                            Button(isListening ? "Stop Listening" : "Start Listening") {
                                if isListening {
                                    stopListening()
                                } else {
                                    startListening()
                                }
                            }
                            .padding()
                            .background(isListening ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Next Technique") {
                                moveToNextTechnique()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        Button("Save Text to Technique") {
                            saveRecognizedTextToTechnique()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        // Delete all aliases button
                        Button("Delete All Aliases") {
                            showDeleteAllConfirmation = true
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        // Confirmation alert
                        .alert(isPresented: $showDeleteAllConfirmation) {
                            Alert(
                                title: Text("Delete All Aliases"),
                                message: Text("Are you sure you want to delete all aliases for this technique?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    deleteAllAliases()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
            .navigationBarTitle("Calibration", displayMode: .inline)
            .onAppear(perform: fetchTechniques)
        }
    }
    
    // MARK: - Delete All Aliases
    private func deleteAllAliases() {
        guard currentTechniqueIndex < techniques.count else { return }
        let currentTechnique = techniques[currentTechniqueIndex]

        currentTechnique.aliases = nil // Clear all aliases

        do {
            try session.managedObjectContext?.save()
            print("All aliases deleted for technique: \(currentTechnique.name ?? "Unnamed")")
        } catch {
            print("Failed to delete all aliases: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Techniques
    private func fetchTechniques() {
        logger.log("Executing fetchTechniques")
        guard let sessionId = session.id else {
            print("Error: Session ID is nil.")
            return
        }

        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as NSUUID)

        do {
            let results = try context.fetch(request)
            if let fetchedSession = results.first,
               let selectedTechniques = fetchedSession.selectedTechniques?.allObjects as? [TechniqueEntity] {
                DispatchQueue.main.async {
                    self.techniques = selectedTechniques
                }
            } else {
                print("No techniques found.")
            }
        } catch {
            print("Error fetching session: \(error)")
        }
    }

    // MARK: - Move to Next Technique
    private func moveToNextTechnique() {
        if currentTechniqueIndex < techniques.count - 1 {
            currentTechniqueIndex += 1
            recognizedText = "" // Reset the recognized text for the next technique
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Start Listening
    private func startListening() {
        shouldRestart = true
        guard !audioEngine.isRunning else {
            print("Audio engine is already running.")
            return
        }

        isListening = true
        recognizedText = "" // Clear previous text

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
            return
        }

        let inputNode = audioEngine.inputNode
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("Audio engine started.")
        } catch {
            print("Audio engine couldn't start: \(error.localizedDescription)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }

            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopListening()

                // Restart only if allowed
                if self.shouldRestart {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        print("Restarting speech recognition after error.")
                        self.startListening()
                    }
                }
            }
        }
    }

    private func stopListening() {
        guard audioEngine.isRunning else {
            print("Audio engine is not running.")
            return
        }

        shouldRestart = false // Prevent restart
        isListening = false

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
    }


    // MARK: - Save Recognized Text to Technique
    private func saveRecognizedTextToTechnique() {
        logger.log("Running saveRecognizedTextToTechnique")
        guard currentTechniqueIndex < techniques.count else { return }

        let currentTechnique = techniques[currentTechniqueIndex]
        logger.log("Attempting to save text to technique: \(currentTechnique.name ?? "Unnamed")")

        var aliases: [String] = []
        if let existingData = currentTechnique.aliases {
            aliases = (try? JSONDecoder().decode([String].self, from: existingData)) ?? []
        }

        aliases.append(recognizedText)

        if let updatedData = try? JSONEncoder().encode(aliases) {
            currentTechnique.aliases = updatedData
        }

        do {
            try session.managedObjectContext?.save()
            print("Saved recognized text to technique: \(recognizedText)")

            // User feedback
            DispatchQueue.main.async {
                recognizedText = "\(recognizedText) (Saved!)"
            }
        } catch {
            print("Failed to save recognized text: \(error.localizedDescription)")
        }
    }


}
