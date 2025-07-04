//
//  CreateTrainingSessionView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

enum ModifySelectionType: Identifiable {
    case kicks, exercises, techniques, katas, blocks, strikes

    var id: Self { self }
}

enum SelectionType: Identifiable {
    case kicks, exercises, techniques, katas, blocks, strikes

    var id: Self { self } // ✅ This makes it work with `.sheet(item:)`
}


struct CreateTrainingSessionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager

    var editingSession: TrainingSessionEntity?

    @State private var sessionName: String = ""
    @State private var selectedTechniques: [Technique] = []
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedKatas: [Kata] = []
    @State private var selectedBlocks: [Block] = []
    @State private var selectedStrikes: [Strike] = []
    @State private var selectedKicks: [Kick] = []
    @State private var randomizeTechniques: Bool = false
    @State private var isFeetTogetherEnabled: Bool = false
    @State private var timeBetweenTechniques: Int = 5

    // Toggles for pausing vs. timer per category
    @State private var useTimerForTechniques: Bool = true
    @State private var useTimerForExercises: Bool = false
    @State private var useTimerForKatas: Bool = true
    @State private var useTimerForBlocks: Bool = true
    @State private var useTimerForStrikes: Bool = true
    @State private var useTimerForKicks: Bool = true
    
    // Timmer values
    @State private var timeForKatas: Int = 30
    @State private var timeForExercises: Int = 10
    @State private var timeForBlocks: Int = 5
    @State private var timeForStrikes: Int = 15
    @State private var timeForKicks: Int = 20
    @State private var timeForTechniques: Int = 10
    
    // Practice Types
    @State private var selectedPracticeType: PracticeType = .soundOff
    
    @State private var selectedModifyType: SelectionType? = nil

    @State private var allTechniques: [Technique] = []
    
    var body: some View {
        Form {
            sessionInfoSection()
            practiceSettingsSection()
            timerSettingsSection()
            modifyTechniquesSection()
            trainingItemsSection()
            saveButton()
        }
        .navigationTitle(editingSession == nil ? "Create Training Session" : "Edit Training Session")
        .onAppear { loadSessionData() }
        .sheet(item: $selectedModifyType) { selectionType in
            switch selectionType {
            case .kicks:
                ModifySelectionView(
                    selectedItems: $selectedKicks,
                    allItems: predefinedKicks.map {
                        var item = $0
                        item.isSelected = selectedKicks.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Kicks"
                )
            case .exercises:
                ModifySelectionView(
                    selectedItems: $selectedExercises,
                    allItems: predefinedExercises.map {
                        var item = $0
                        item.isSelected = selectedExercises.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Exercises"
                )
            case .techniques:
                ModifySelectionView(
                    selectedItems: $selectedTechniques,
                    allItems: predefinedTechniques.map {
                        var item = $0
                        item.isSelected = selectedTechniques.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Techniques"
                )
            case .katas:
                ModifySelectionView(
                    selectedItems: $selectedKatas,
                    allItems: predefinedKatas.map {
                        var item = $0
                        item.isSelected = selectedKatas.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Katas"
                )
            case .blocks:
                ModifySelectionView(
                    selectedItems: $selectedBlocks,
                    allItems: predefinedBlocks.map {
                        var item = $0
                        item.isSelected = selectedBlocks.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Blocks"
                )
            case .strikes:
                ModifySelectionView(
                    selectedItems: $selectedStrikes,
                    allItems: predefinedStrikes.map {
                        var item = $0
                        item.isSelected = selectedStrikes.contains(where: { $0.id == item.id && $0.isSelected })
                        return item
                    },
                    headerTitle: "Modify Strikes"
                )
            }
        }

    }
    
    private func trainingItemsSection() -> some View {
        Group {
            // Filter kicks to only show selected ones
            let filteredKicks = selectedKicks.filter { $0.isSelected }
            modifySelectionSection(
                header: "Kicks (\(filteredKicks.count) selected)",
                selectedType: .kicks,
                items: Binding(
                    get: { filteredKicks },
                    set: { newValue in
                        // When items are reordered, we need to update the full array
                        let updatedKicks = selectedKicks.filter { !$0.isSelected }
                        selectedKicks = updatedKicks + newValue
                    }
                ),
                updateOrder: updateKickOrderIndexes
            )
            
            // Filter exercises to only show selected ones
            let filteredExercises = selectedExercises.filter { $0.isSelected }
            modifySelectionSection(
                header: "Exercises (\(filteredExercises.count) selected)",
                selectedType: .exercises,
                items: Binding(
                    get: { filteredExercises },
                    set: { newValue in
                        let updatedExercises = selectedExercises.filter { !$0.isSelected }
                        selectedExercises = updatedExercises + newValue
                    }
                ),
                updateOrder: updateExerciseOrderIndexes
            )
            
            // Filter katas to only show selected ones
            let filteredKatas = selectedKatas.filter { $0.isSelected }
            modifySelectionSection(
                header: "Katas (\(filteredKatas.count) selected)",
                selectedType: .katas,
                items: Binding(
                    get: { filteredKatas },
                    set: { newValue in
                        let updatedKatas = selectedKatas.filter { !$0.isSelected }
                        selectedKatas = updatedKatas + newValue
                    }
                ),
                updateOrder: updateKataOrderIndexes
            )
            
            // Filter blocks to only show selected ones
            let filteredBlocks = selectedBlocks.filter { $0.isSelected }
            modifySelectionSection(
                header: "Blocks (\(filteredBlocks.count) selected)",
                selectedType: .blocks,
                items: Binding(
                    get: { filteredBlocks },
                    set: { newValue in
                        let updatedBlocks = selectedBlocks.filter { !$0.isSelected }
                        selectedBlocks = updatedBlocks + newValue
                    }
                ),
                updateOrder: updateBlockOrderIndexes
            )
            
            // Filter strikes to only show selected ones
            let filteredStrikes = selectedStrikes.filter { $0.isSelected }
            modifySelectionSection(
                header: "Strikes (\(filteredStrikes.count) selected)",
                selectedType: .strikes,
                items: Binding(
                    get: { filteredStrikes },
                    set: { newValue in
                        let updatedStrikes = selectedStrikes.filter { !$0.isSelected }
                        selectedStrikes = updatedStrikes + newValue
                    }
                ),
                updateOrder: updateStrikeOrderIndexes
            )
        }
    }

    
    private func moveTechnique(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex else { return }

        let technique = selectedTechniques.remove(at: oldIndex)
        selectedTechniques.insert(technique, at: newIndex)
        
        updateOrderIndexes()  // Update the orderIndex values
        saveSessionOrder()    // Save changes to Core Data
    }

    private func loadAllTechniques() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TechniqueEntity> = TechniqueEntity.fetchRequest()

        do {
            let techniqueEntities = try context.fetch(request)
            allTechniques = techniqueEntities.map { entity in
                Technique(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "Unnamed",
                    orderIndex: Int(entity.orderIndex),
                    beltLevel: BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown,
                    timeToComplete: Int(entity.timeToComplete),
                    isSelected: false // Default to false, user selects in ModifyTechniquesView
                )
            }
        } catch {
            print("Failed to load techniques: \(error.localizedDescription)")
        }
    }



    
    // Helper function to populate and sort predefined items
    private func populateAndSort<T: Identifiable & Equatable>(
        predefinedItems: [T],
        selectedItems: [T],
        sortCriteria: (T, T) -> Bool
    ) -> [T] {
        var items = selectedItems
        
        for predefinedItem in predefinedItems where !items.contains(where: { $0.id == predefinedItem.id }) {
            let item = predefinedItem
            if var mutableItem = item as? Selectable {
                mutableItem.isSelected = false
                items.append(mutableItem as! T)
            }
        }
        
        items.sort(by: sortCriteria)
        return items
    }


    private func toggleTechniqueSelection(at index: Int) {
        // Toggle the selected state at the index
        selectedTechniques[index].isSelected.toggle()
        print("Toggled technique: \(selectedTechniques[index].name), selected: \(selectedTechniques[index].isSelected)")
    }

    // Helper to toggle selection for exercises
    private func toggleExerciseSelection(at index: Int) {
        selectedExercises[index].isSelected.toggle()
        print("Toggled exercise: \(selectedExercises[index].name), selected: \(selectedExercises[index].isSelected)")
    }

    private func updateExerciseOrderIndexes() {
        for (index, exercise) in selectedExercises.enumerated() {
            selectedExercises[index].orderIndex = index
            print("Updated exercise: \(exercise.name), new orderIndex: \(index)")
        }
    }

    private func updateKickOrderIndexes() {
        for index in 0..<selectedKicks.count {
            selectedKicks[index].orderIndex = index
        }
    }

    private func toggleKataSelection(at index: Int) {
        selectedKatas[index].isSelected.toggle()
        print("Toggled kata: \(selectedKatas[index].name), selected: \(selectedKatas[index].isSelected)")
    }
    
    private func updateKataOrderIndexes() {
        for (index, kata) in selectedKatas.enumerated() {
            selectedKatas[index].orderIndex = index
            print("Updated kata: \(kata.name), new orderIndex: \(index)")
        }
    }

    private func toggleBlockSelection(at index: Int) {
        selectedBlocks[index].isSelected.toggle()
        print("Toggled block: \(selectedBlocks[index].name), selected: \(selectedBlocks[index].isSelected)")
    }
    
    private func updateBlockOrderIndexes() {
        for (index, block) in selectedBlocks.enumerated() {
            selectedBlocks[index].orderIndex = index
            print("Updated block: \(block.name), new orderIndex: \(index)")
        }
    }
    
    // Helper to toggle selection for strikes
    private func toggleStrikeSelection(at index: Int) {
        selectedStrikes[index].isSelected.toggle()
        print("Toggled strike: \(selectedStrikes[index].name), selected: \(selectedStrikes[index].isSelected)")
    }
    
    // Helper to toggle selection for kicks
    private func toggleKickSelection(at index: Int) {
        selectedKicks[index].isSelected.toggle()
        print("Toggled kick: \(selectedKicks[index].name), selected: \(selectedKicks[index].isSelected)")
    }

    // Helper to update orderIndex for strikes
    private func updateStrikeOrderIndexes() {
        for (index, strike) in selectedStrikes.enumerated() {
            selectedStrikes[index].orderIndex = index
            print("Updated strike: \(strike.name), new orderIndex: \(index)")
        }
    }
    
    private func updateOrderIndexes() {
        for (index, _) in selectedTechniques.enumerated() {
            selectedTechniques[index].orderIndex = index
        }
    }


    private func saveSessionOrder() {
        // Fetch the current session from Core Data
        guard let session = editingSession else {
            print("❌ Error: No session to save.")
            return
        }
        
        let context = PersistenceController.shared.container.viewContext
        
        // Function to check if an entity already exists in Core Data
        func entityExists<T: NSManagedObject>(_ entityType: T.Type, id: UUID) -> Bool {
            let request = NSFetchRequest<T>(entityName: String(describing: entityType))
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                return try context.count(for: request) > 0
            } catch {
                print("Error checking for existing entity: \(error.localizedDescription)")
                return false
            }
        }
        
        // ✅ Removes items that are no longer selected and updates Core Data relationships
        func removeUnselectedItems<T: NSManagedObject>(_ currentItems: Set<T>?, selectedIds: Set<UUID>) -> Set<T> {
            guard let existingItems = currentItems else { return Set<T>() }
            
            let filteredItems = existingItems.filter { entity in
                if let entityId = entity.value(forKey: "id") as? UUID {
                    return selectedIds.contains(entityId) // ✅ Keep only selected items
                }
                return false
            }
            
            // ✅ Delete items that are no longer selected
            for entity in existingItems where !filteredItems.contains(entity) {
                context.delete(entity)
            }
            
            return filteredItems // ✅ Return the updated Set<T>
        }
        
        // ✅ Remove unselected items from each Core Data relationship
        session.selectedTechniques = removeUnselectedItems(session.selectedTechniques as? Set<TechniqueEntity>, selectedIds: Set(selectedTechniques.map { $0.id })) as NSSet
        session.selectedExercises = removeUnselectedItems(session.selectedExercises as? Set<ExerciseEntity>, selectedIds: Set(selectedExercises.map { $0.id })) as NSSet
        session.selectedBlocks = removeUnselectedItems(session.selectedBlocks as? Set<BlockEntity>, selectedIds: Set(selectedBlocks.map { $0.id })) as NSSet
        session.selectedStrikes = removeUnselectedItems(session.selectedStrikes as? Set<StrikeEntity>, selectedIds: Set(selectedStrikes.map { $0.id })) as NSSet
        session.selectedKicks = removeUnselectedItems(session.selectedKicks as? Set<KickEntity>, selectedIds: Set(selectedKicks.map { $0.id })) as NSSet

        let uniqueTechniques = Dictionary(uniqueKeysWithValues: selectedTechniques.map { ($0.id, $0) })
        for (index, technique) in uniqueTechniques.values.enumerated() {
            if !entityExists(TechniqueEntity.self, id: technique.id) {
                let techniqueEntity = TechniqueEntity(context: context)
                techniqueEntity.id = technique.id
                techniqueEntity.name = technique.name
                techniqueEntity.beltLevel = technique.beltLevel.rawValue
                techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
                techniqueEntity.orderIndex = Int16(index) // Save the updated order index
                techniqueEntity.isSelected = technique.isSelected
                session.addToSelectedTechniques(techniqueEntity)
            }
        }
        

        // ✅ Ensure unique exercises before adding
        for (index, exercise) in selectedExercises.enumerated() where exercise.isSelected {
            if !entityExists(ExerciseEntity.self, id: exercise.id) {
                let exerciseEntity = ExerciseEntity(context: context)
                exerciseEntity.id = exercise.id
                exerciseEntity.name = exercise.name
                exerciseEntity.orderIndex = Int16(index)
                exerciseEntity.isSelected = exercise.isSelected
                session.addToSelectedExercises(exerciseEntity)
            }
        }

        // ✅ Ensure unique blocks before adding
        for (index, block) in selectedBlocks.enumerated() where block.isSelected {
            if !entityExists(BlockEntity.self, id: block.id) {
                let blockEntity = BlockEntity(context: context)
                blockEntity.id = block.id
                blockEntity.name = block.name
                blockEntity.orderIndex = Int16(index)
                blockEntity.isSelected = block.isSelected
                session.addToSelectedBlocks(blockEntity)
            }
        }

        // ✅ Ensure unique strikes before adding
        for (index, strike) in selectedStrikes.enumerated() where strike.isSelected {
            if !entityExists(StrikeEntity.self, id: strike.id) {
                let strikeEntity = StrikeEntity(context: context)
                strikeEntity.id = strike.id
                strikeEntity.name = strike.name
                strikeEntity.orderIndex = Int16(index)
                strikeEntity.isSelected = strike.isSelected
                session.addToSelectedStrikes(strikeEntity)
            }
        }

        // ✅ Ensure unique kicks before adding
        for (index, kick) in selectedKicks.enumerated() where kick.isSelected {
            if !entityExists(KickEntity.self, id: kick.id) {
                let kickEntity = KickEntity(context: context)
                kickEntity.id = kick.id
                kickEntity.name = kick.name
                kickEntity.orderIndex = Int16(index)
                kickEntity.isSelected = kick.isSelected
                session.addToSelectedKicks(kickEntity)
            }
        }

        // ✅ Save the context
        do {
            if context.hasChanges {
                try context.save()
                print("✅ Session order saved successfully.")
            } else {
                print("⚠️ No changes detected. Nothing was saved.")
            }
        } catch {
            print("❌ Failed to save session order: \(error.localizedDescription)")
        }
    }
    
    private func saveSession() {
        print("Saving session: \(sessionName)")
        
        let sessionToSave: TrainingSessionEntity

        if let editingSession = editingSession {
            sessionToSave = editingSession
        } else {
            let newSession = TrainingSessionEntity(context: context)
            newSession.id = UUID()
            sessionToSave = newSession
        }
        
        // ✅ Update session properties
        sessionToSave.name = sessionName
        sessionToSave.randomizeTechniques = randomizeTechniques
        sessionToSave.isFeetTogetherEnabled = isFeetTogetherEnabled
        sessionToSave.timeBetweenTechniques = Int16(timeBetweenTechniques)
        sessionToSave.practiceType = selectedPracticeType.rawValue

        sessionToSave.useTimerForTechniques = useTimerForTechniques
        sessionToSave.useTimerForExercises = useTimerForExercises
        sessionToSave.useTimerForKatas = useTimerForKatas
        sessionToSave.useTimerForBlocks = useTimerForBlocks
        sessionToSave.useTimerForStrikes = useTimerForStrikes
        sessionToSave.useTimerForKicks = useTimerForKicks

        sessionToSave.timeForKatas = Int16(timeForKatas)
        sessionToSave.timeForExercises = Int16(timeForExercises)
        sessionToSave.timeForBlocks = Int16(timeForBlocks)
        sessionToSave.timeForStrikes = Int16(timeForStrikes)
        sessionToSave.timeForKicks = Int16(timeForKicks)
        sessionToSave.timeForTechniques = Int16(timeForTechniques)

        // ✅ Ensure previous selections are removed before saving new ones
        sessionToSave.selectedTechniques = nil
        sessionToSave.selectedExercises = nil
        sessionToSave.selectedBlocks = nil
        sessionToSave.selectedStrikes = nil
        sessionToSave.selectedKatas = nil
        sessionToSave.selectedKicks = nil
        
        // Debugging output before filtering
        print("BEFORE FIXING - Selected kicks count: \(selectedKicks.filter { $0.isSelected }.count)")
        print("BEFORE FIXING - Selected techniques count: \(selectedTechniques.filter { $0.isSelected }.count)")
        
        // Make sure selected items have isSelected = true if needed
        for index in 0..<selectedTechniques.count {
            if selectedTechniques[index].isSelected == false {
                print("WARNING: Technique \(selectedTechniques[index].name) was in selected array but had isSelected=false, fixing")
                selectedTechniques[index].isSelected = true
            }
        }
        
        // Same check for kicks
        for index in 0..<selectedKicks.count {
            if selectedKicks[index].isSelected == false {
                // Don't change anything, we want to keep this as false
                print("INFO: Kick \(selectedKicks[index].name) is not selected in the array")
            } else {
                print("INFO: Kick \(selectedKicks[index].name) is selected in the array")
            }
        }
        
        let filteredSelectedTechniques = selectedTechniques.filter { $0.isSelected }
        print("BEFORE FILTER selectedTechniques: \(selectedTechniques.map { $0.name })")
        print("AFTER FILTER filteredSelectedTechniques: \(filteredSelectedTechniques.map { $0.name })")

        let filteredSelectedExercises = selectedExercises.filter { $0.isSelected }
        let filteredSelectedBlocks = selectedBlocks.filter { $0.isSelected }
        let filteredSelectedStrikes = selectedStrikes.filter { $0.isSelected }
        let filteredSelectedKatas = selectedKatas.filter { $0.isSelected }
        let filteredSelectedKicks = selectedKicks.filter { $0.isSelected } // Filter kicks to match other items

        
        print("BEFORE FILTER selectedKicks: \(selectedKicks.map { $0.name })")
        print("AFTER FILTER filteredSelectedKicks: \(filteredSelectedKicks.map { $0.name })")


        print("Filtered Selected Techniques: \(filteredSelectedTechniques.map { $0.name })")

        for (index, technique) in filteredSelectedTechniques.enumerated() {
            let techniqueEntity = TechniqueEntity(context: context)
            techniqueEntity.id = technique.id
            techniqueEntity.name = technique.name
            techniqueEntity.beltLevel = technique.beltLevel.rawValue
            techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
            techniqueEntity.orderIndex = Int16(index)
            techniqueEntity.isSelected = technique.isSelected

            sessionToSave.addToSelectedTechniques(techniqueEntity) // ✅ Make sure this runs
            print("✅ SAVED: \(techniqueEntity.name ?? "Unnamed") - Order: \(index) - Selected: \(techniqueEntity.isSelected)")
        }

        // ✅ Save Exercises
        let selectedExercisesSet = Set(filteredSelectedExercises.map { exercise in
            let entity = ExerciseEntity(context: context)
            entity.id = exercise.id
            entity.name = exercise.name
            entity.orderIndex = Int16(filteredSelectedExercises.firstIndex(of: exercise) ?? 0)
            return entity
        })
        sessionToSave.selectedExercises = selectedExercisesSet as NSSet

        // ✅ Save Blocks
        let selectedBlocksSet = Set(filteredSelectedBlocks.map { block in
            let entity = BlockEntity(context: context)
            entity.id = block.id
            entity.name = block.name
            entity.orderIndex = Int16(filteredSelectedBlocks.firstIndex(of: block) ?? 0)
            return entity
        })
        sessionToSave.selectedBlocks = selectedBlocksSet as NSSet

        // ✅ Save Strikes
        let selectedStrikesSet = Set(filteredSelectedStrikes.map { strike in
            let entity = StrikeEntity(context: context)
            entity.id = strike.id
            entity.name = strike.name
            entity.orderIndex = Int16(filteredSelectedStrikes.firstIndex(of: strike) ?? 0)
            return entity
        })
        sessionToSave.selectedStrikes = selectedStrikesSet as NSSet

        // ✅ Save Katas
        let selectedKatasSet = Set(filteredSelectedKatas.map { kata in
            let entity = KataEntity(context: context)
            entity.id = kata.id
            entity.name = kata.name
            entity.kataNumber = Int16(kata.kataNumber)
            entity.orderIndex = Int16(filteredSelectedKatas.firstIndex(of: kata) ?? 0)
            return entity
        })
        sessionToSave.selectedKatas = selectedKatasSet as NSSet

        // ✅ Save Kicks
        for (index, kick) in filteredSelectedKicks.enumerated() {
            let kickEntity = KickEntity(context: context)
            kickEntity.id = kick.id
            kickEntity.name = kick.name
            kickEntity.orderIndex = Int16(index)
            kickEntity.isSelected = true // ✅ Ensure it saves as selected
            sessionToSave.addToSelectedKicks(kickEntity)
            print("✅ SAVED KICK: \(kick.name) - Order: \(index)")
        }

        // ✅ Save Core Data
        do {
            try context.save()
            print("✅ Session saved successfully.")

            // Debugging: Fetch saved sessions after saving
            let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
            let savedSessions = try context.fetch(request)
            print("✅ Fetched \(savedSessions.count) sessions after save.")
            
            // Ensure the saved session has the right count of techniques
            if let savedSession = savedSessions.first(where: { $0.id == sessionToSave.id }) {
                print("✅ Saved session has \(savedSession.selectedTechniques?.count ?? 0) techniques")
                print("✅ Saved session has \(savedSession.selectedExercises?.count ?? 0) exercises")
                print("✅ Saved session has \(savedSession.selectedKatas?.count ?? 0) katas")
                print("✅ Saved session has \(savedSession.selectedBlocks?.count ?? 0) blocks")
                print("✅ Saved session has \(savedSession.selectedStrikes?.count ?? 0) strikes")
                print("✅ Saved session has \(savedSession.selectedKicks?.count ?? 0) kicks")
            }

            // Force a complete refresh of the data
            DispatchQueue.main.async {
                // First refresh
                dataManager.fetchTrainingSessions()
                
                // Trigger UI refresh
                dataManager.shouldRefresh.toggle()
                
                // Dismiss after a short delay to ensure data is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch let error as NSError {
            print("❌ Failed to save session: \(error.localizedDescription)")
        }

        
        print("Techniques saved: \(sessionToSave.selectedTechniques?.count ?? 0)")
        print("Exercises saved: \(sessionToSave.selectedExercises?.count ?? 0)")
        print("Katas saved: \(sessionToSave.selectedKatas?.count ?? 0)")
        print("Blocks saved: \(sessionToSave.selectedBlocks?.count ?? 0)")
        print("Strikes saved: \(sessionToSave.selectedStrikes?.count ?? 0)")
        print("Kicks saved: \(sessionToSave.selectedKicks?.count ?? 0)")

    }



    private func loadSessionData(_ session: TrainingSessionEntity) {
        print("Loading session data for session: \(session.name ?? "Unnamed Session")")

        sessionName = session.name ?? ""
        randomizeTechniques = session.randomizeTechniques
        isFeetTogetherEnabled = session.isFeetTogetherEnabled
        if let practiceType = session.practiceType {
            selectedPracticeType = PracticeType(rawValue: practiceType) ?? .soundOff
        }
        timeBetweenTechniques = Int(session.timeBetweenTechniques)
        useTimerForTechniques = session.useTimerForTechniques
        useTimerForExercises = session.useTimerForExercises
        useTimerForKatas = session.useTimerForKatas
        useTimerForBlocks = session.useTimerForBlocks
        useTimerForStrikes = session.useTimerForStrikes
        useTimerForKicks = session.useTimerForKicks
        
        timeForKatas = Int(session.timeForKatas)
        timeForExercises = Int(session.timeForExercises)
        timeForBlocks = Int(session.timeForBlocks)
        timeForStrikes = Int(session.timeForStrikes)
        timeForKicks = Int(session.timeForKicks)
        timeForTechniques = Int(session.timeForTechniques)

        // Reset selected data and populate from the session
        selectedTechniques.removeAll()
        selectedExercises.removeAll()
        selectedBlocks.removeAll()
        selectedStrikes.removeAll()
        selectedKatas.removeAll()
        selectedKicks.removeAll()

        //
        // Load techniques and sort them by orderIndex
        //
        if let techniques = session.selectedTechniques as? Set<TechniqueEntity> {
            let sortedTechniques = techniques.sorted { $0.orderIndex < $1.orderIndex }
            for techniqueEntity in sortedTechniques {
                if let matchingTechnique = predefinedTechniques.first(where: { $0.id == techniqueEntity.id }) {
                    var technique = matchingTechnique
                    technique.isSelected = true // Mark this technique as selected
                    technique.orderIndex = Int(techniqueEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedTechniques.append(technique)
                } else {
                    print("Could not find a matching predefined technique for ID: \(techniqueEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined techniques are in the list, even if not selected
        for predefinedTechnique in predefinedTechniques where !selectedTechniques.contains(where: { $0.id == predefinedTechnique.id }) {
            var technique = predefinedTechnique
            technique.isSelected = false // Mark as not selected
            selectedTechniques.append(technique)
        }

        print("Selected Techniques for editing session (in order): \(selectedTechniques.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load exercises and sort them by orderIndex
        //
        if let exercises = session.selectedExercises as? Set<ExerciseEntity> {
            let sortedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
            for exerciseEntity in sortedExercises {
                if let matchingExercise = predefinedExercises.first(where: { $0.id == exerciseEntity.id }) {
                    var exercise = matchingExercise
                    exercise.isSelected = true // Mark this exercise as selected
                    exercise.orderIndex = Int(exerciseEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedExercises.append(exercise)
                } else {
                    print("Could not find a matching predefined exercise for ID: \(exerciseEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined exercises are in the list, even if not selected
        for predefinedExercise in predefinedExercises where !selectedExercises.contains(where: { $0.id == predefinedExercise.id }) {
            var exercise = predefinedExercise
            exercise.isSelected = false // Mark as not selected
            selectedExercises.append(exercise)
        }

        print("Selected Exercises for editing session (in order): \(selectedExercises.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load blocks and sort them by orderIndex
        //
        if let blocks = session.selectedBlocks as? Set<BlockEntity> {
            let sortedBlocks = blocks.sorted { $0.orderIndex < $1.orderIndex }
            for blockEntity in sortedBlocks {
                if let matchingBlock = predefinedBlocks.first(where: { $0.id == blockEntity.id }) {
                    var block = matchingBlock
                    block.isSelected = true
                    block.orderIndex = Int(blockEntity.orderIndex)
                    selectedBlocks.append(block)
                } else {
                    print("Could not find a matching predefined block for ID: \(blockEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined blocks are in the list, even if not selected
        for predefinedBlock in predefinedBlocks where !selectedBlocks.contains(where: { $0.id == predefinedBlock.id }) {
            var block = predefinedBlock
            block.isSelected = false
            selectedBlocks.append(block)
        }

        print("Selected Blocks for editing session (in order): \(selectedBlocks.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load strikes and sort them by orderIndex
        //
        if let strikes = session.selectedStrikes as? Set<StrikeEntity> {
            let sortedStrikes = strikes.sorted { $0.orderIndex < $1.orderIndex }
            for strikeEntity in sortedStrikes {
                if let matchingStrike = predefinedStrikes.first(where: { $0.id == strikeEntity.id }) {
                    var strike = matchingStrike
                    strike.isSelected = true
                    strike.orderIndex = Int(strikeEntity.orderIndex)
                    selectedStrikes.append(strike)
                } else {
                    print("Could not find a matching predefined strike for ID: \(strikeEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined strikes are in the list, even if not selected
        for predefinedStrike in predefinedStrikes where !selectedStrikes.contains(where: { $0.id == predefinedStrike.id }) {
            var strike = predefinedStrike
            strike.isSelected = false
            selectedStrikes.append(strike)
        }

        print("Selected Strikes for editing session (in order): \(selectedStrikes.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load katas and log them
        //
        if let katas = session.selectedKatas as? Set<KataEntity> {
            let sortedKatas = katas.sorted { $0.orderIndex < $1.orderIndex }
            for kataEntity in sortedKatas {
                if let matchingKata = predefinedKatas.first(where: { $0.id == kataEntity.id }) {
                    var kata = matchingKata
                    kata.isSelected = true // Mark as selected
                    kata.orderIndex = Int(kataEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedKatas.append(kata)
                } else {
                    print("Could not find a matching predefined kata for ID: \(kataEntity.id?.uuidString ?? "nil")")
                }
            }
        }
        // Ensure that all predefined strikes are in the list, even if not selected
        for predefinedKata in predefinedKatas where !selectedKatas.contains(where: { $0.id == predefinedKata.id }) {
            var kata = predefinedKata
            kata.isSelected = false
            selectedKatas.append(kata)
        }
        // Log the selected katas
        print("Selected Katas for editing session: \(selectedKatas.map { $0.name })")
        
        
        // Load selected kicks from the session
        if let kicks = session.selectedKicks as? Set<KickEntity> {
            let sortedKicks = kicks.sorted { $0.orderIndex < $1.orderIndex }
            for kickEntity in sortedKicks {
                if let matchingKick = predefinedKicks.first(where: { $0.id == kickEntity.id }) {
                    var kick = matchingKick
                    kick.isSelected = true // Mark the predefined kick as selected
                    kick.orderIndex = Int(kickEntity.orderIndex)
                    selectedKicks.append(kick)
                    print("Loaded selected kick: \(kick.name), ID: \(kick.id), OrderIndex: \(kick.orderIndex)")
                } else {
                    print("Could not find a matching predefined kick for ID: \(kickEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure all predefined kicks are included, even if not selected
        for predefinedKick in predefinedKicks where !selectedKicks.contains(where: { $0.id == predefinedKick.id }) {
            var unselectedKick = predefinedKick
            unselectedKick.isSelected = false // Mark as unselected
            selectedKicks.append(unselectedKick)
            print("Added unselected predefined kick: \(unselectedKick.name), ID: \(unselectedKick.id)")
        }
        
        // Verify selected status of all kicks
        print("Loaded kicks with selection status:")
        for kick in selectedKicks {
            print("Kick: \(kick.name), isSelected: \(kick.isSelected)")
        }

        // Sort the kicks by orderIndex
        selectedKicks.sort { $0.orderIndex < $1.orderIndex }
        print("Selected Kicks for editing session: \(selectedKicks.map { "\($0.name) - selected: \($0.isSelected)" })")
    }


}

extension CreateTrainingSessionView {
    
    // MARK: - Session Info Section
    private func sessionInfoSection() -> some View {
        Section(header: Text("Session Info")) {
            TextField("Session Name", text: $sessionName)
            Toggle("Randomize Techniques", isOn: $randomizeTechniques)
            Toggle("Feet Together Mode", isOn: $isFeetTogetherEnabled)
        }
    }

    // MARK: - Practice Type and Timer Toggles
    private func practiceSettingsSection() -> some View {
        Section(header: Text("Practice Type for Techniques")) {
            Picker("Practice Type", selection: $selectedPracticeType) {
                ForEach(PracticeType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    // MARK: - Timer Settings
    private func timerSettingsSection() -> some View {
        Section(header: Text("Set Timer Durations")) {
            Stepper("Time for Techniques: \(timeForTechniques) seconds", value: $timeForTechniques, in: 1...30)
            Stepper("Time for Katas: \(timeForKatas) seconds", value: $timeForKatas, in: 1...60)
            Stepper("Time for Exercises: \(timeForExercises) seconds", value: $timeForExercises, in: 1...60)
            Stepper("Time for Blocks: \(timeForBlocks) seconds", value: $timeForBlocks, in: 1...60)
            Stepper("Time for Strikes: \(timeForStrikes) seconds", value: $timeForStrikes, in: 1...60)
            Stepper("Time for Kicks: \(timeForKicks) seconds", value: $timeForKicks, in: 1...60)
        }
    }

    // MARK: - Modify Techniques Button
    private func modifyTechniquesSection() -> some View {
        // Filter to show only selected techniques
        let filteredTechniques = selectedTechniques.filter { $0.isSelected }
        
        return Section(header: Text("Techniques (\(filteredTechniques.count) selected)")) {
            Button(action: {
                print("Modify Selection button tapped!")
                selectedModifyType = .techniques
            }) {
                Text("Modify Selection")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibilityIdentifier("ModifyTechniquesButton")

            List {
                ForEach(filteredTechniques, id: \.id) { technique in
                    HStack {
                        Text(technique.name)
                        Spacer()
                        Image(systemName: "line.horizontal.3") // Drag handle
                    }
                    .contentShape(Rectangle()) // Ensures entire row is tappable
                }
                .onMove { indices, newOffset in
                    var mutableFiltered = filteredTechniques
                    mutableFiltered.move(fromOffsets: indices, toOffset: newOffset)
                    
                    // Update the main array
                    let unselectedTechniques = selectedTechniques.filter { !$0.isSelected }
                    selectedTechniques = unselectedTechniques + mutableFiltered
                    
                    updateOrderIndexes()
                    saveSessionOrder()
                }
            }
            .environment(\.editMode, .constant(.active)) // Enables drag-and-drop
        }
    }

    // MARK: - Training Items (Kicks, Exercises, Katas, Blocks, Strikes)
    private func modifySelectionSection<T>(
        header: String,
        selectedType: SelectionType,
        items: Binding<[T]>,
        updateOrder: @escaping () -> Void
    ) -> some View where T: Identifiable & Selectable {
        Section(header: Text(header)) {
            Button(action: {
                print("Modify Selection button tapped for \(header)!")
                selectedModifyType = selectedType
            }) {
                Text("Modify \(header)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            List {
                ForEach(items.wrappedValue, id: \.id) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Image(systemName: "line.horizontal.3") // Drag handle
                    }
                    .contentShape(Rectangle()) // Ensures entire row is tappable
                }
                .onMove { indices, newOffset in
                    items.wrappedValue.move(fromOffsets: indices, toOffset: newOffset)
                    updateOrder()
                    saveSessionOrder()
                }
            }
            .environment(\.editMode, .constant(.active)) // Enables drag-and-drop
        }
    }


    // MARK: - Generic Training List Section
    private func trainingListSection<T>(
        header: String,
        items: Binding<[T]>,
        toggleSelection: @escaping (Int) -> Void,
        updateOrder: @escaping () -> Void,
        modifyAction: @escaping () -> Void  // ✅ New modify button action
    ) -> some View where T: Identifiable & Selectable {
        Section(header: Text(header)) {
            
            // ✅ Add "Modify Selection" button at the top
            Button(action: modifyAction) {
                Text("Modify \(header)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            List {
                ForEach(Array(selectedTechniques.enumerated()), id: \.element.id) { index, technique in
                    HStack {
                        Text(technique.name)
                        Spacer()
                        if technique.isSelected {
                            Image(systemName: "checkmark")
                        }
                        Image(systemName: "line.horizontal.3")
                    }
                    .contentShape(Rectangle()) // This ensures the entire row is tappable
                    .onTapGesture {
                        selectedTechniques[index].isSelected.toggle()
                        print("Toggled technique: \(selectedTechniques[index].name), selected: \(selectedTechniques[index].isSelected)")
                    }
                }
                .onMove { indices, newOffset in
                    selectedTechniques.move(fromOffsets: indices, toOffset: newOffset)
                    updateOrderIndexes()
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }

    // MARK: - Save Button
    private func saveButton() -> some View {
        Button(action: saveSession) {
            Text("Save Session")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
        }
        .accessibilityIdentifier("SaveSessionButton")
    }

    // MARK: - Load Session Data
    private func loadSessionData() {
        print("Editing session: \(editingSession?.name ?? "No session")")
        
        if let session = editingSession {
            let sessionData = dataManager.loadSessionData(session)
            
            // ✅ Load session properties
            sessionName = sessionData.name
            randomizeTechniques = sessionData.randomizeTechniques
            isFeetTogetherEnabled = sessionData.isFeetTogetherEnabled
            selectedPracticeType = sessionData.practiceType
            timeBetweenTechniques = sessionData.timeBetweenTechniques
            useTimerForTechniques = sessionData.useTimerForTechniques
            useTimerForExercises = sessionData.useTimerForExercises
            useTimerForKatas = sessionData.useTimerForKatas
            useTimerForBlocks = sessionData.useTimerForBlocks
            useTimerForStrikes = sessionData.useTimerForStrikes
            useTimerForKicks = sessionData.useTimerForKicks
            timeForTechniques = sessionData.timeForTechniques
            timeForExercises = sessionData.timeForExercises
            timeForKatas = sessionData.timeForKatas
            timeForBlocks = sessionData.timeForBlocks
            timeForStrikes = sessionData.timeForStrikes
            timeForKicks = sessionData.timeForKicks
            
            // ✅ Ensure ALL selections are loaded
            selectedTechniques = sessionData.selectedTechniques
            selectedExercises = sessionData.selectedExercises
            selectedKatas = sessionData.selectedKatas
            selectedBlocks = sessionData.selectedBlocks
            selectedStrikes = sessionData.selectedStrikes
            selectedKicks = sessionData.selectedKicks

            // ✅ Debugging Output
            print("Loaded Techniques: \(selectedTechniques.count)")
            print("Loaded Exercises: \(selectedExercises.count)")
            print("Loaded Katas: \(selectedKatas.count)")
            print("Loaded Blocks: \(selectedBlocks.count)")
            print("Loaded Strikes: \(selectedStrikes.count)")
            print("Loaded Kicks: \(selectedKicks.count)")
        }
    }

}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
