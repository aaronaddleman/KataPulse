//
//  GlobalSettingsView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 11/29/24.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct GlobalSettingsView: View {
    @ObservedObject private var watchManager = WatchManager.shared
    @State private var exportedFileURL: URL? // URL to store the exported file
    @State private var isExporting = false   // State for file export
    @State private var isImporting = false   // State for file import
    @State private var showResetConfirmation = false // State to show the confirmation dialog

    private let context = PersistenceController.shared.container.viewContext

    var body: some View {
        Form {
            Section(header: Text("Device Status")) {
                HStack {
                    Text("Watch Paired:")
                    Spacer()
                    Text(watchManager.isPaired ? "Yes" : "No")
                        .foregroundColor(watchManager.isPaired ? .green : .red)
                }

                HStack {
                    Text("Watch Reachable:")
                    Spacer()
                    Text(watchManager.isReachable ? "Yes" : "No")
                        .foregroundColor(watchManager.isReachable ? .green : .red)
                }

                HStack {
                    Text("App Installed:")
                    Spacer()
                    Text(watchManager.isWatchAppInstalled ? "Yes" : "No")
                        .foregroundColor(watchManager.isWatchAppInstalled ? .green : .red)
                }

                Button(action: {
                    watchManager.updateConnectivityStatus()
                }) {
                    HStack {
                        Spacer()
                        Text("Refresh Status")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Section(header: Text("Preferences")) {
                Toggle("Enable Randomization", isOn: .constant(true))
                Toggle("Enable Feet Together", isOn: .constant(false))
            }
            
            Section(header: Text("Data Management")) {
                Button("Export Core Data to JSON") {
                    exportCoreDataToJSON()
                }
                .fileExporter(
                    isPresented: $isExporting,
                    document: FileDocumentWrapper(url: exportedFileURL),
                    contentType: .json,
                    defaultFilename: generateExportFilename()
                ) { result in
                    switch result {
                    case .success(let url):
                        print("File saved to \(url)")
                    case .failure(let error):
                        print("Error saving file: \(error)")
                    }
                }
                
                Button("Import Core Data from JSON") {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            // This ensures the file is downloaded if it's in iCloud
                            accessICloudFile(at: url)
                        }
                    case .failure(let error):
                        print("Error selecting file: \(error)")
                    }
                }

                Button("Reset Core Data") {
                    showResetConfirmation = true // Show confirmation dialog
                }
                .foregroundColor(.red)
                .confirmationDialog(
                    "Are you sure you want to reset all Core Data?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Yes, I am totally sure I want to do this", role: .destructive) {
                        resetCoreData()
                    }
                    Button("No! This was a really big mistake and I want to keep my data", role: .cancel) {}
                }
            }
        }
        .navigationTitle("Global Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func accessICloudFile(at url: URL) {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                try importCoreDataFromJSON(data: data)
            } catch {
                print("Failed to read the file: \(error)")
            }
        } else {
            print("Unable to access the file at \(url).")
        }
    }

    /// Function to export Core Data to a JSON file
    private func exportCoreDataToJSON() {
        let context = PersistenceController.shared.container.viewContext

        do {
            // Fetch Training Sessions
            let trainingSessionFetch: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
            let trainingSessions = try context.fetch(trainingSessionFetch)

            let trainingSessionData = trainingSessions.map { session -> [String: Any] in
                return [
                    "id": session.id?.uuidString ?? UUID().uuidString,
                    "name": session.name ?? "Unnamed Session",
                    "isFeetTogetherEnabled": session.isFeetTogetherEnabled,
                    "randomizeTechniques": session.randomizeTechniques,
                    "timeBetweenTechniques": session.timeBetweenTechniques,
                    "timeForBlocks": session.timeForBlocks,
                    "timeForExercises": session.timeForExercises,
                    "timeForKatas": session.timeForKatas,
                    "timeForKicks": session.timeForKicks,
                    "timeForStrikes": session.timeForStrikes,
                    "timeForTechniques": session.timeForTechniques,
                    "useTimerForBlocks": session.useTimerForBlocks,
                    "useTimerForExercises": session.useTimerForExercises,
                    "useTimerForKatas": session.useTimerForKatas,
                    "useTimerForKicks": session.useTimerForKicks,
                    "useTimerForStrikes": session.useTimerForStrikes,
                    "useTimerForTechniques": session.useTimerForTechniques,
                    "selectedBlocks": (session.selectedBlocks as? Set<BlockEntity>)?.map { block in
                        [
                            "id": block.id?.uuidString ?? UUID().uuidString,
                            "name": block.name ?? "Unnamed Block",
                            "isSelected": block.isSelected,
                            "orderIndex": block.orderIndex,
                            "repetitions": block.repetitions,
                            "timestamp": block.timestamp?.description ?? ""
                        ]
                    } ?? [],
                    "selectedExercises": (session.selectedExercises as? Set<ExerciseEntity>)?.map { exercise in
                        [
                            "id": exercise.id?.uuidString ?? UUID().uuidString,
                            "name": exercise.name ?? "Unnamed Exercise",
                            "isSelected": exercise.isSelected,
                            "orderIndex": exercise.orderIndex
                        ]
                    } ?? [],
                    "selectedKatas": (session.selectedKatas as? Set<KataEntity>)?.map { kata in
                        [
                            "id": kata.id?.uuidString ?? UUID().uuidString,
                            "name": kata.name ?? "Unnamed Kata",
                            "kataNumber": kata.kataNumber,
                            "isSelected": kata.isSelected,
                            "orderIndex": kata.orderIndex
                        ]
                    } ?? [],
                    "selectedKicks": (session.selectedKicks as? Set<KickEntity>)?.map { kick in
                        [
                            "id": kick.id?.uuidString ?? UUID().uuidString,
                            "name": kick.name ?? "Unnamed Kick",
                            "isSelected": kick.isSelected,
                            "orderIndex": kick.orderIndex
                        ]
                    } ?? [],
                    "selectedStrikes": (session.selectedStrikes as? Set<StrikeEntity>)?.map { strike in
                        [
                            "id": strike.id?.uuidString ?? UUID().uuidString,
                            "name": strike.name ?? "Unnamed Strike",
                            "isSelected": strike.isSelected,
                            "isBothSides": strike.isBothSides,
                            "leftCompleted": strike.leftCompleted,
                            "rightCompleted": strike.rightCompleted,
                            "preferredStance": strike.preferredStance ?? "Unknown",
                            "repetitions": strike.repetitions,
                            "requiresBothSides": strike.requiresBothSides,
                            "timePerMove": strike.timePerMove,
                            "watchDetectedCompletion": strike.watchDetectedCompletion,
                            "timestamp": strike.timestamp?.description ?? ""
                        ]
                    } ?? [],
                    "selectedTechniques": (session.selectedTechniques as? Set<TechniqueEntity>)?.map { technique in
                        [
                            "id": technique.id?.uuidString ?? UUID().uuidString,
                            "name": technique.name ?? "Unnamed Technique",
                            "beltLevel": technique.beltLevel ?? "Unknown",
                            "isSelected": technique.isSelected,
                            "orderIndex": technique.orderIndex,
                            "timeToComplete": technique.timeToComplete,
                            "timestamp": technique.timestamp?.description ?? ""
                        ]
                    } ?? []
                ]
            }

            // Fetch Training Session History
            let historyFetch: NSFetchRequest<TrainingSessionHistoryEntity> = TrainingSessionHistoryEntity.fetchRequest()
            let historyEntities = try context.fetch(historyFetch)

            let historyData = historyEntities.map { entity -> [String: Any] in
                return [
                    "id": entity.id?.uuidString ?? UUID().uuidString,
                    "sessionName": entity.sessionName ?? "Unnamed Session",
                    "timestamp": entity.timestamp?.description ?? "",
                    "items": (entity.items as? Set<TrainingSessionHistoryItemsEntity>)?.map { itemEntity in
                        return [
                            "id": itemEntity.id?.uuidString ?? UUID().uuidString,
                            "exerciseName": itemEntity.exerciseName ?? "Unnamed Exercise",
                            "timeTaken": itemEntity.timeTaken,
                            "type": itemEntity.type ?? "Unknown",
                            "isKnown": itemEntity.isKnown
                        ]
                    } ?? []
                ]
            }

            // Combine all data into a single JSON structure
            let allData = [
                "trainingSessions": trainingSessionData,
                "history": historyData
            ]

            // Serialize JSON
            let jsonData = try JSONSerialization.data(withJSONObject: allData, options: .prettyPrinted)

            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KataPulse_\(currentDateString()).json")
            try jsonData.write(to: tempURL)

            // Set file URL for export
            exportedFileURL = tempURL
            isExporting = true
        } catch {
            print("Failed to export Core Data to JSON: \(error)")
        }
    }

    /// Helper function to get the current date as a string
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }


    /// Function to import Core Data from a JSON file
    private func importCoreDataFromJSON(url: URL) {
        let context = PersistenceController.shared.container.viewContext

        do {
            // Read JSON data from the URL
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Invalid JSON format")
                return
            }

            // Process Training Sessions
            if let trainingSessions = json["trainingSessions"] as? [[String: Any]] {
                for sessionData in trainingSessions {
                    if let idString = sessionData["id"] as? String,
                       let id = UUID(uuidString: idString) {
                        // Check if session already exists
                        let fetchRequest: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        
                        if try context.fetch(fetchRequest).isEmpty {
                            let session = TrainingSessionEntity(context: context)
                            session.id = id
                            session.name = sessionData["name"] as? String
                            session.isFeetTogetherEnabled = sessionData["isFeetTogetherEnabled"] as? Bool ?? false
                            session.randomizeTechniques = sessionData["randomizeTechniques"] as? Bool ?? false
                            session.timeBetweenTechniques = sessionData["timeBetweenTechniques"] as? Int16 ?? 0
                            session.timeForBlocks = sessionData["timeForBlocks"] as? Int16 ?? 0
                            session.timeForExercises = sessionData["timeForExercises"] as? Int16 ?? 0
                            session.timeForKatas = sessionData["timeForKatas"] as? Int16 ?? 0
                            session.timeForKicks = sessionData["timeForKicks"] as? Int16 ?? 0
                            session.timeForStrikes = sessionData["timeForStrikes"] as? Int16 ?? 0
                            session.timeForTechniques = sessionData["timeForTechniques"] as? Int16 ?? 0
                            session.useTimerForBlocks = sessionData["useTimerForBlocks"] as? Bool ?? false
                            session.useTimerForExercises = sessionData["useTimerForExercises"] as? Bool ?? false
                            session.useTimerForKatas = sessionData["useTimerForKatas"] as? Bool ?? false
                            session.useTimerForKicks = sessionData["useTimerForKicks"] as? Bool ?? false
                            session.useTimerForStrikes = sessionData["useTimerForStrikes"] as? Bool ?? false
                            session.useTimerForTechniques = sessionData["useTimerForTechniques"] as? Bool ?? true

                            // Restore relationships
                            if let selectedBlocks = sessionData["selectedBlocks"] as? [[String: Any]] {
                                for blockData in selectedBlocks {
                                    let block = BlockEntity(context: context)
                                    block.id = UUID(uuidString: blockData["id"] as? String ?? UUID().uuidString)
                                    block.name = blockData["name"] as? String
                                    block.isSelected = blockData["isSelected"] as? Bool ?? false
                                    block.orderIndex = blockData["orderIndex"] as? Int16 ?? 0
                                    block.repetitions = blockData["repetitions"] as? Int16 ?? 0
                                    block.timestamp = ISO8601DateFormatter().date(from: blockData["timestamp"] as? String ?? "")
                                    block.trainingSession = session
                                }
                            }

                            if let selectedExercises = sessionData["selectedExercises"] as? [[String: Any]] {
                                for exerciseData in selectedExercises {
                                    let exercise = ExerciseEntity(context: context)
                                    exercise.id = UUID(uuidString: exerciseData["id"] as? String ?? UUID().uuidString)
                                    exercise.name = exerciseData["name"] as? String
                                    exercise.isSelected = exerciseData["isSelected"] as? Bool ?? false
                                    exercise.orderIndex = exerciseData["orderIndex"] as? Int16 ?? 0
                                    exercise.trainingSession = session
                                }
                            }

                            if let selectedKatas = sessionData["selectedKatas"] as? [[String: Any]] {
                                for kataData in selectedKatas {
                                    let kata = KataEntity(context: context)
                                    kata.id = UUID(uuidString: kataData["id"] as? String ?? UUID().uuidString)
                                    kata.name = kataData["name"] as? String
                                    kata.kataNumber = kataData["kataNumber"] as? Int16 ?? 0
                                    kata.isSelected = kataData["isSelected"] as? Bool ?? false
                                    kata.orderIndex = kataData["orderIndex"] as? Int16 ?? 0
                                    kata.trainingSession = session
                                }
                            }

                            if let selectedKicks = sessionData["selectedKicks"] as? [[String: Any]] {
                                for kickData in selectedKicks {
                                    let kick = KickEntity(context: context)
                                    kick.id = UUID(uuidString: kickData["id"] as? String ?? UUID().uuidString)
                                    kick.name = kickData["name"] as? String
                                    kick.isSelected = kickData["isSelected"] as? Bool ?? false
                                    kick.orderIndex = kickData["orderIndex"] as? Int16 ?? 0
                                    kick.trainingSession = session
                                }
                            }

                            if let selectedStrikes = sessionData["selectedStrikes"] as? [[String: Any]] {
                                for strikeData in selectedStrikes {
                                    let strike = StrikeEntity(context: context)
                                    strike.id = UUID(uuidString: strikeData["id"] as? String ?? UUID().uuidString)
                                    strike.name = strikeData["name"] as? String
                                    strike.isSelected = strikeData["isSelected"] as? Bool ?? false
                                    strike.isBothSides = strikeData["isBothSides"] as? Bool ?? false
                                    strike.leftCompleted = strikeData["leftCompleted"] as? Bool ?? false
                                    strike.rightCompleted = strikeData["rightCompleted"] as? Bool ?? false
                                    strike.preferredStance = strikeData["preferredStance"] as? String
                                    strike.repetitions = strikeData["repetitions"] as? Int16 ?? 0
                                    strike.requiresBothSides = strikeData["requiresBothSides"] as? Bool ?? false
                                    strike.timePerMove = strikeData["timePerMove"] as? Int16 ?? 0
                                    strike.watchDetectedCompletion = strikeData["watchDetectedCompletion"] as? Bool ?? false
                                    strike.timestamp = ISO8601DateFormatter().date(from: strikeData["timestamp"] as? String ?? "")
                                    strike.trainingSession = session
                                }
                            }

                            if let selectedTechniques = sessionData["selectedTechniques"] as? [[String: Any]] {
                                for techniqueData in selectedTechniques {
                                    let technique = TechniqueEntity(context: context)
                                    technique.id = UUID(uuidString: techniqueData["id"] as? String ?? UUID().uuidString)
                                    technique.name = techniqueData["name"] as? String
                                    technique.beltLevel = techniqueData["beltLevel"] as? String
                                    technique.isSelected = techniqueData["isSelected"] as? Bool ?? false
                                    technique.orderIndex = techniqueData["orderIndex"] as? Int16 ?? 0
                                    technique.timeToComplete = techniqueData["timeToComplete"] as? Int16 ?? 0
                                    technique.timestamp = ISO8601DateFormatter().date(from: techniqueData["timestamp"] as? String ?? "")
                                    technique.trainingSession = session
                                }
                            }
                        }
                    }
                }
            }

            // Process Training Session History
            if let history = json["history"] as? [[String: Any]] {
                for historyData in history {
                    if let idString = historyData["id"] as? String,
                       let id = UUID(uuidString: idString) {
                        // Check if history already exists
                        let fetchRequest: NSFetchRequest<TrainingSessionHistoryEntity> = TrainingSessionHistoryEntity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        
                        if try context.fetch(fetchRequest).isEmpty {
                            let historyEntity = TrainingSessionHistoryEntity(context: context)
                            historyEntity.id = id
                            historyEntity.sessionName = historyData["sessionName"] as? String
                            historyEntity.timestamp = ISO8601DateFormatter().date(from: historyData["timestamp"] as? String ?? "")

                            if let items = historyData["items"] as? [[String: Any]] {
                                for itemData in items {
                                    let itemEntity = TrainingSessionHistoryItemsEntity(context: context)
                                    itemEntity.id = UUID(uuidString: itemData["id"] as? String ?? UUID().uuidString)
                                    itemEntity.exerciseName = itemData["exerciseName"] as? String
                                    itemEntity.isKnown = itemData["isKnown"] as? Bool ?? false
                                    itemEntity.timeTaken = itemData["timeTaken"] as? Double ?? 0
                                    itemEntity.type = itemData["type"] as? String
                                    itemEntity.history = historyEntity
                                }
                            }
                        }
                    }
                }
            }

            // Save the context
            try context.save()
            print("Core Data successfully imported from JSON")
        } catch {
            print("Failed to import Core Data from JSON: \(error)")
        }
    }


    
    /// Generate export filename in the format "KataPulse_YEARMONTHDAY.json"
    private func generateExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        return "KataPulse_\(dateString).json"
    }
}

/// Wrapper for the file to be exported
struct FileDocumentWrapper: FileDocument {
    var url: URL?
    
    static var readableContentTypes: [UTType] { [.json] }
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        // No-op
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else {
            throw NSError(domain: "No file URL found", code: 1, userInfo: nil)
        }
        return try FileWrapper(url: url)
    }
}

func resetCoreData() {
    let persistentContainer = PersistenceController.shared.container
    let context = persistentContainer.viewContext

    // Get the store URL
    guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
        print("Failed to retrieve the persistent store URL.")
        return
    }

    // Perform the reset
    do {
        try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
            at: storeURL,
            ofType: NSSQLiteStoreType,
            options: nil
        )
        try persistentContainer.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )
        print("Core Data has been successfully reset.")
    } catch {
        print("Failed to reset Core Data: \(error)")
    }

    // Optionally, clear in-memory objects
    context.reset()
}
