//
//  LibraryView.swift
//  Iridum
//
//  Created by Francesco on 01/12/24.
//

import Foundation
import Kingfisher
import SwiftUI

struct LibraryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let imageUrl: String
    let href: String
    var isFavorite: Bool
    var isFinished: Bool
}

class LibraryViewModel: ObservableObject {
    @Published var items: [LibraryItem] = []
    
    init() {
        loadItems()
    }
    
    func addItem(_ item: LibraryItem) {
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        saveItems()
    }
    
    func updateItem(_ item: LibraryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    func removeItem(_ item: LibraryItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "bookmarkedMedia")
        }
    }
    
    private func loadItems() {
        if let savedItems = UserDefaults.standard.data(forKey: "bookmarkedMedia"),
           let decodedItems = try? JSONDecoder().decode([LibraryItem].self, from: savedItems) {
            items = decodedItems
        }
    }
    
    var favoriteItems: [LibraryItem] {
        items.filter { $0.isFavorite }
    }
    
    var finishedItems: [LibraryItem] {
        items.filter { $0.isFinished }
    }
    
    var otherItems: [LibraryItem] {
        items.filter { !$0.isFavorite && !$0.isFinished }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Watching")) {
                    ForEach(libraryViewModel.favoriteItems) { item in
                        LibraryItemView(item: item)
                    }
                }
                
                Section(header: Text("Planning")) {
                    ForEach(libraryViewModel.otherItems) { item in
                        LibraryItemView(item: item)
                    }
                }
                
                Section(header: Text("Finished")) {
                    ForEach(libraryViewModel.finishedItems) { item in
                        LibraryItemView(item: item)
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}

struct LibraryItemView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    var item: LibraryItem
    
    var body: some View {
        NavigationLink(destination: MediaView(
            title: item.title,
            imageUrl: item.imageUrl,
            href: item.href
        )) {
            HStack {
                KFImage(URL(string: item.imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 90)
                    .clipped()
                    .cornerRadius(5)
                
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.href)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 5)
        }
        .swipeActions(edge: .leading) {
            Button(action: {
                var updatedItem = item
                updatedItem.isFavorite.toggle()
                libraryViewModel.updateItem(updatedItem)
            }) {
                Label("Favorite", systemImage: "star")
            }
            .tint(.yellow)
            
            Button(action: {
                var updatedItem = item
                updatedItem.isFinished.toggle()
                libraryViewModel.updateItem(updatedItem)
            }) {
                Label("Finished", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                libraryViewModel.removeItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}
