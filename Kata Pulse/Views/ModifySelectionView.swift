//
//  ModifySelectionView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 2/9/25.
//

import SwiftUI

struct ModifySelectionView<T: Identifiable & Selectable & BeltLevelItem>: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedItems: [T] // ✅ Stores only selected items
    var allItems: [T] // ✅ Stores all possible choices
    var headerTitle: String

    var body: some View {
        NavigationView {
            List {
                ForEach(BeltLevel.allCases, id: \.self) { beltLevel in
                    if let items = groupedItems[beltLevel], !items.isEmpty {
                        Section(header: Text(beltLevel.rawValue)) {
                            ForEach(items, id: \.id) { item in
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    if isSelected(item) { // ✅ Keep this, this is correct
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(item)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(headerTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save and Return") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accessibilityIdentifier("SaveAndReturnButton")
                }
            }
        }
    }

    // Group items by belt level, preserving their isSelected property
    private var groupedItems: [BeltLevel: [T]] {
        // Simply group the items by belt level, no need to modify isSelected
        // since we've already set it correctly in the allItems parameter
        return Dictionary(grouping: allItems, by: { $0.beltLevel })
    }

    private func isSelected(_ item: T) -> Bool {
        // Check if the item exists in selectedItems AND is marked as selected
        selectedItems.contains { $0.id == item.id && $0.isSelected }
    }

    private func toggleSelection(_ item: T) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            // Toggle the isSelected flag instead of removing
            if selectedItems[index].isSelected {
                selectedItems[index].isSelected = false
                print("Deselected: \(selectedItems[index].name)")
            } else {
                selectedItems[index].isSelected = true
                print("Selected: \(selectedItems[index].name)")
            }
        } else {
            // Add item to selected items and mark it as selected
            var selectedItem = item
            selectedItem.isSelected = true
            selectedItems.append(selectedItem)
            print("Added new item: \(selectedItem.name)")
        }
    }

}
