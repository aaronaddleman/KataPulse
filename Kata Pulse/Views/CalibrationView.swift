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

enum ValidationMode: String {
    case none = "None"
    case simple = "Simple Match"
    case fuzzy = "Fuzzy Match"
}

public struct CalibrationView: View {
    @Environment(\.presentationMode) var presentationMode
    let session: TrainingSessionEntity
    @State private var techniques: [TechniqueEntity] = []
    @State private var currentTechniqueIndex: Int = 0
    @State private var isListening: Bool = false
    @State private var recognizedText: String = ""
    @State private var showDeleteAllConfirmation = false
    @State private var shouldRestart: Bool = true
    @State private var validationMode: ValidationMode = .none
    @State private var validationResult: String? = nil // Result of validation
    @State private var isTestingRecognition: Bool = false


    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionTask: SFSpeechRecognitionTask?

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

                        if let aliasesData = techniques[currentTechniqueIndex].aliases,
                           let aliases = try? JSONDecoder().decode([String].self, from: aliasesData) {
                            Text("Aliases:")
                                .font(.headline)
                                .padding(.top)

                            List {
                                ForEach(Array(aliases.enumerated()), id: \.offset) { index, alias in
                                    Text(alias)
                                        .padding(.vertical, 10) // Increase row height for better touch targets
                                }
                                .onDelete { indices in
                                    indices.forEach { deleteAlias(at: $0) }
                                }
                            }
                        } else {
                            Text("No aliases saved yet.")
                                .foregroundColor(.gray)
                        }

                        Picker("Validation Mode", selection: $validationMode) {
                            Text("None").tag(ValidationMode.none)
                            Text("Simple Match").tag(ValidationMode.simple)
                            Text("Fuzzy Match").tag(ValidationMode.fuzzy)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // Validation result display
                        if let validationResult = validationResult {
                            Text("Validation Result: \(validationResult)")
                                .font(.headline)
                                .foregroundColor(validationResult == "Match Found!" ? .green : .red)
                                .padding()
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
    
    private func testRecognition() {
        guard currentTechniqueIndex < techniques.count else { return }
        let currentTechnique = techniques[currentTechniqueIndex]

        // Decode aliases
        var aliases: [String] = []
        if let existingData = currentTechnique.aliases {
            aliases = (try? JSONDecoder().decode([String].self, from: existingData)) ?? []
        }

        // Match logic
        let techniqueName = currentTechnique.name ?? ""
        if techniqueName.lowercased() == recognizedText.lowercased() || aliases.contains(where: { $0.lowercased() == recognizedText.lowercased() }) {
            validationResult = "Match Found!"
            logger.log("Recognition matched technique: \(techniqueName)")
        } else {
            validationResult = "No Match Found!"
            logger.log("Recognition did not match any alias.")
        }

        print("Validation Result: \(validationResult ?? "No result") for recognized text: \(recognizedText)")
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
        guard !audioEngine.isRunning else {
            print("Audio engine is already running.")
            return
        }

        shouldRestart = true
        isListening = true
        recognizedText = "" // Clear previous recognized text

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated successfully.")
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
            isListening = false
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
            isListening = false
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized text: \(self.recognizedText)")

                    if !self.recognizedText.isEmpty && self.validationMode != .none {
                        self.validationResult = self.validateText(self.recognizedText, fuzzy: self.validationMode == .fuzzy)
                    }
                }
            }

            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                self.stopListening()

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

        shouldRestart = false
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
    
    // MARK: - Validate Text
    private func validateText(_ text: String, fuzzy: Bool) -> String {
        guard currentTechniqueIndex < techniques.count else { return "Invalid Technique" }
        let currentTechnique = techniques[currentTechniqueIndex]

        let techniqueName = currentTechnique.name ?? ""
        var aliases: [String] = []
        if let existingData = currentTechnique.aliases {
            aliases = (try? JSONDecoder().decode([String].self, from: existingData)) ?? []
        }

        // Check if the input text is empty
        if text.isEmpty {
            return "No Match Found!"
        }

        if fuzzy {
            let allNames = [techniqueName] + aliases
            for name in allNames {
                let distance = levenshteinDistance(text.lowercased(), name.lowercased())
                if distance <= 2 { // Adjust threshold as needed
                    return "Match Found!"
                }
            }
            return "No Match Found!"
        } else {
            if techniqueName.lowercased() == text.lowercased() || aliases.contains(where: { $0.lowercased() == text.lowercased() }) {
                return "Match Found!"
            } else {
                return "No Match Found!"
            }
        }
    }
    
    private func deleteAlias(at index: Int) {
        guard currentTechniqueIndex < techniques.count else { return }
        let currentTechnique = techniques[currentTechniqueIndex]

        // Decode existing aliases
        if let existingData = currentTechnique.aliases,
           var aliases = try? JSONDecoder().decode([String].self, from: existingData) {
            // Remove alias at the given index
            aliases.remove(at: index)

            // Encode the updated aliases back to the Data format
            if let updatedData = try? JSONEncoder().encode(aliases) {
                currentTechnique.aliases = updatedData

                // Save the changes to Core Data
                do {
                    try session.managedObjectContext?.save()
                    print("Deleted alias at index \(index) for technique: \(currentTechnique.name ?? "Unnamed Technique")")
                } catch {
                    print("Failed to save after deleting alias: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Save Recognized Text to Technique
    private func saveRecognizedTextToTechnique() {
        logger.log("Running saveRecognizedTextToTechnique")
        guard currentTechniqueIndex < techniques.count else { return }

        let currentTechnique = techniques[currentTechniqueIndex]
        logger.log("Attempting to save text to technique: \(currentTechnique.name ?? "Unnamed")")

        // Use the clean recognized text (before appending "(Saved!)")
        let cleanText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)

        var aliases: [String] = []
        if let existingData = currentTechnique.aliases {
            aliases = (try? JSONDecoder().decode([String].self, from: existingData)) ?? []
        }

        // Prevent duplicates (case insensitive)
        if aliases.contains(where: { $0.caseInsensitiveCompare(cleanText) == .orderedSame }) {
            print("Alias '\(cleanText)' already exists. Not adding.")
            return // Exit early if the alias already exists
        }

        aliases.append(cleanText) // Append the clean recognized text
        aliases = Array(Set(aliases)) // Optional: Ensure uniqueness again

        if let updatedData = try? JSONEncoder().encode(aliases) {
            currentTechnique.aliases = updatedData
        }

        do {
            try session.managedObjectContext?.save()
            print("Saved recognized text to technique: \(cleanText)")

            // User feedback
            DispatchQueue.main.async {
                recognizedText = "\(cleanText) (Saved!)" // Feedback for UI only
            }
        } catch {
            print("Failed to save recognized text: \(error.localizedDescription)")
        }
    }

}
