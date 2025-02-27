//
//  PersistenceController.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/27/24.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory || CommandLine.arguments.contains("--use-in-memory-core-data")
        let shouldResetState = CommandLine.arguments.contains("--reset-app-state")
        
        container = NSPersistentContainer(name: "FeetTogetherModel")
        
        if self.inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if shouldResetState {
            // If testing with real storage but need to reset, delete the store
            deleteStore()
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Clear Core Data entities if reset flag is set
        if shouldResetState {
            resetAllEntities()
        }
    }
    
    private func deleteStore() {
        // Find the store URL and delete it
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            print("Successfully deleted persistent store at \(storeURL)")
        } catch {
            print("Failed to delete persistent store: \(error)")
        }
    }
    
    // Clear all entities from the Core Data store
    func resetAllEntities() {
        let context = container.viewContext
        let entityNames = container.managedObjectModel.entities.compactMap { $0.name }
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.persistentStoreCoordinator.execute(batchDeleteRequest, with: context)
                try context.save()
                print("Cleared all \(entityName) entities")
            } catch {
                print("Error clearing \(entityName) entities: \(error)")
            }
        }
    }
}

