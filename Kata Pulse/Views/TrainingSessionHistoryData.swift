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
        
        do {
            let sessions = try context.fetch(fetchRequest)
            self.historySessions = sessions
        } catch {
            print("Failed to fetch training session history: \(error)")
        }
    }

    // Fetch all history items for a specific session
    func getHistoryItems(for session: TrainingSessionHistoryEntity) -> [TrainingSessionHistoryItemsEntity] {
        let historyItemsSet = session.items as? Set<TrainingSessionHistoryItemsEntity> ?? []
        return Array(historyItemsSet)
    }
}
