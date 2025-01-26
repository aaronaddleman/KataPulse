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
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "CalibrationView")
    
    public init(session: TrainingSessionEntity) {
        self.session = session
    }

    public var body: some View {
        NavigationView {
            VStack {
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

                        Text(recognizedText)
                            .font(.body)
                            .padding()
                            .foregroundColor(.gray)

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
                    }
                }
            }
            .navigationBarTitle("Calibration", displayMode: .inline)
            .onAppear(perform: fetchTechniques)
        }
    }


    private func fetchTechniques() {
        // print log saying the fetchTechniques is being executed
        logger.log("executing fetchTechniques")
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


    private func moveToNextTechnique() {
        if currentTechniqueIndex < techniques.count - 1 {
            currentTechniqueIndex += 1
            recognizedText = "" // Reset the recognized text for the next technique
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func startListening() {
        isListening = true
        // Configure and start speech recognition logic here
    }

    private func stopListening() {
        isListening = false
        // Stop speech recognition logic here
    }

    private func saveRecognizedTextToTechnique() {
        logger.log("running saveRecognizedTextToTechnique")
        let currentTechnique = techniques[currentTechniqueIndex]
        
        logger.log("Attempting to save text to technique: \(currentTechnique.name ?? "Unnamed")")


        // Update alias handling logic to work with Core Data's Data type
        var aliases: [String] = []
        if let existingData = currentTechnique.aliases as? Data {
            aliases = (try? JSONDecoder().decode([String].self, from: existingData)) ?? []
        }

        aliases.append(recognizedText)

        if let updatedData = try? JSONEncoder().encode(aliases) {
            currentTechnique.aliases = updatedData
        }

        do {
            try session.managedObjectContext?.save()
        } catch {
            print("Failed to save recognized text: \(error)")
        }
    }
}
//
//struct CalibrationView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Mock data for previews
//        let mockContext = PersistenceController.preview.container.viewContext
//        let mockSession = TrainingSessionEntity(context: mockContext)
//        CalibrationView(session: mockSession)
//    }
//}
