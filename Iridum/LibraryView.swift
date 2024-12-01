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
    var id: String { href }
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
        guard !items.contains(where: { $0.href == item.href }) else { return }
        items.append(item)
        saveItems()
    }
    
    func removeItem(withHref href: String) {
        items.removeAll { $0.href == href }
        saveItems()
    }
    
    func updateItem(_ item: LibraryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }
    
    func saveItems() {
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
}

struct LibraryView: View {
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if libraryViewModel.items.isEmpty {
                    VStack {
                        Text("Your library is empty.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(libraryViewModel.items) { item in
                            LibraryItemView(item: item)
                        }
                    }
                    .padding()
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
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: MediaView(
                title: item.title,
                imageUrl: item.imageUrl,
                href: item.href
            )) {
                KFImage(URL(string: item.imageUrl))
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                var updatedItem = item
                updatedItem.isFavorite.toggle()
                libraryViewModel.updateItem(updatedItem)
            }) {
                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                    .font(.title)
                    .foregroundColor(item.isFavorite ? .red : .white)
                    .padding(8)
            }
        }
        .frame(width: 150, height: 225)
        .overlay(
            VStack {
                Spacer()
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding([.leading, .bottom], 8)
                    .lineLimit(2)
            }
        )
    }
}
