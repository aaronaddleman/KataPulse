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
                }
            }
        }
    }

    // ✅ Fix: Ensure only previously selected items start selected
    private var groupedItems: [BeltLevel: [T]] {
        let selectedIds = Set(selectedItems.map { $0.id }) // Track selected items
        return Dictionary(grouping: allItems, by: { $0.beltLevel }).mapValues { items in
            items.map { item in
                var updatedItem = item
                updatedItem.isSelected = selectedIds.contains(item.id) // ✅ Only mark selected ones
                return updatedItem
            }
        }
    }

    private func isSelected(_ item: T) -> Bool {
        selectedItems.contains { $0.id == item.id }
    }

    private func toggleSelection(_ item: T) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item) // ✅ No isSelected mutation needed
        }
    }

}
