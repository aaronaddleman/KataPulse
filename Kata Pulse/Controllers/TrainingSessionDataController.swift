//
//  TrainingSessionDataController.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/24/25.
//

import Foundation
import CoreData
import Combine

class TrainingSessionDataController: ObservableObject {
    static let shared = TrainingSessionDataController()
    
    private let context = PersistenceController.shared.container.viewContext

    @Published var trainingSessions: [TrainingSessionEntity] = []
    @Published var selectedSession: TrainingSessionEntity?

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        fetchTrainingSessions()
    }

    func fetchTrainingSessions() {
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            trainingSessions = try context.fetch(request)
        } catch {
            print("Error fetching training sessions: \(error)")
        }
    }

    func saveSession(_ session: TrainingSessionEntity) {
        do {
            try context.save()
            fetchTrainingSessions() // Refresh data
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    func deleteSession(_ session: TrainingSessionEntity) {
        context.delete(session)
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
            fetchTrainingSessions() // Refresh data
        } catch {
            print("Error saving context: \(error)")
        }
    }

    func loadSessionData(for session: TrainingSessionEntity) {
        selectedSession = session
        // Add additional setup if required
    }
}
