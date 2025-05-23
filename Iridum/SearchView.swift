//
//  SearchView.swift
//  Iridum
//
//  Created by Francesco on 06/12/24.
//

import SwiftUI
import SwiftSoup
import Kingfisher

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let imageUrl: String
    let href: String
}

struct SearchView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @State private var searchText: String = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var navigateToResults: Bool = false
    
    @State private var searchHistory: [String] = UserDefaults.standard.stringArray(forKey: "SearchHistory") ?? []
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if !searchHistory.isEmpty {
                        Section(header: Text("Search History")) {
                            ForEach(searchHistory, id: \.self) { historyItem in
                                Button(action: {
                                    searchText = historyItem
                                    performSearch()
                                }) {
                                    Text(historyItem)
                                        .foregroundColor(.primary)
                                }
                            }
                            .onDelete(perform: deleteHistoryItem)
                        }
                    }
                }
                .navigationTitle("Search")
                .searchable(text: $searchText)
                .onSubmit(of: .search) {
                    performSearch()
                }
                
                NavigationLink(
                    destination: ResultsView(results: searchResults),
                    isActive: $navigateToResults,
                    label: {
                        EmptyView()
                    }
                )
                    .hidden()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func performSearch() {
        guard !searchText.isEmpty else { return }
        isLoading = true
        let query = searchText.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://\(appSettings.baseDomain)/it/archive?search=\(query)"
        
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async {
            do {
                let html = try String(contentsOf: url)
                let document = try SwiftSoup.parse(html)
                
                if let appDiv = try document.getElementById("app") {
                    let dataPage = try appDiv.attr("data-page")
                    if let jsonData = dataPage.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let props = json["props"] as? [String: Any],
                       let titles = props["titles"] as? [[String: Any]] {
                        DispatchQueue.main.async {
                            self.searchResults = titles.compactMap { titleDict in
                                guard let name = titleDict["name"] as? String,
                                      let id = titleDict["id"] as? Int,
                                      let slug = titleDict["slug"] as? String,
                                      let images = titleDict["images"] as? [[String: Any]],
                                      let poster = images.first(where: { $0["type"] as? String == "poster" }),
                                      let imageUrl = poster["filename"] as? String else {
                                          return nil
                                      }
                                let href = "https://\(appSettings.baseDomain)/it/titles/\(id)-\(slug)"
                                return SearchResult(name: name, imageUrl: "https://cdn.\(appSettings.baseDomain)/images/\(imageUrl)", href: href)
                            }
                            self.isLoading = false
                            if !self.searchHistory.contains(self.searchText) {
                                self.searchHistory.append(self.searchText)
                                UserDefaults.standard.set(self.searchHistory, forKey: "SearchHistory")
                            }
                            self.navigateToResults = true
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    Logger.shared.log("Error fetching or parsing data: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteHistoryItem(at offsets: IndexSet) {
        searchHistory.remove(atOffsets: offsets)
        UserDefaults.standard.set(self.searchHistory, forKey: "SearchHistory")
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search...", text: $text, onCommit: onSearchButtonClicked)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
        }
    }
}

struct ResultsView: View {
    let results: [SearchResult]
    
    var body: some View {
        List {
            ForEach(results) { result in
                NavigationLink(destination: MediaView(
                    title: result.name,
                    imageUrl: result.imageUrl,
                    href: result.href
                )) {
                    HStack {
                        KFImage(URL(string: result.imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 90)
                            .clipped()
                            .cornerRadius(5)
                        
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .font(.headline)
                            Text(result.href)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Results")
    }
}

