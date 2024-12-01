//
//  TrainingSessionHistoryData.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/6/24.
//

import Foundation
import CoreData

class TrainingSessionHistoryData: ObservableObject {
    @Published var historySessions: [TrainingSessionHistoryEntity] = []

    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchHistorySessions()
    }

    // Fetch all training session histories from Core Data
    func fetchHistorySessions() {
        let fetchRequest: NSFetchRequest<TrainingSessionHistoryEntity> = TrainingSessionHistoryEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingSessionHistoryEntity.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 50 // Limit results for better performance
        
        context.perform { [weak self] in
            do {
                let sessions = try self?.context.fetch(fetchRequest)
                DispatchQueue.main.async {
                    self?.historySessions = sessions ?? []
                }
            } catch {
                print("Failed to fetch training session history: \(error)")
            }
        }
    }

    // Fetch all history items for a specific session
    func getHistoryItems(for session: TrainingSessionHistoryEntity) -> [TrainingSessionHistoryItemsEntity] {
        let fetchRequest: NSFetchRequest<TrainingSessionHistoryItemsEntity> = TrainingSessionHistoryItemsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "history == %@", session)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exerciseName", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch history items for session \(session.sessionName ?? "Unnamed Session"): \(error)")
            return []
        }
    }
}
