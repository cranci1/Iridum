//
//  HomeView.swift
//  Iridum
//
//  Created by Francesco on 25/11/24.
//

import SwiftUI
import SwiftSoup
import Kingfisher

struct HomeView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @State private var sliders: [Slider] = []
    @State private var isLoading: Bool = false
    @State private var isLoaded: Bool = false
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    ScrollView {
                        PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                            fetchSliders()
                        }
                        ForEach(sliders) { slider in
                            VStack(alignment: .leading) {
                                Text(slider.label)
                                    .font(.title2)
                                    .bold()
                                    .padding(.leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(slider.titles) { title in
                                            NavigationLink(destination: MediaView(
                                                title: title.name,
                                                imageUrl: title.imageUrl,
                                                href: title.href
                                            )) {
                                                VStack {
                                                    KFImage(URL(string: title.imageUrl))
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 120, height: 180)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                    
                                                    Text(title.name)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .foregroundColor(.white)
                                                }
                                                .frame(width: 120)
                                                .padding(.leading, 5)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .coordinateSpace(name: "pullToRefresh")
                    .navigationTitle("Home")
                }
            }
            .onAppear {
                if !isLoaded {
                    fetchSliders()
                    isLoaded = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func fetchSliders() {
        isLoading = true
        let urlString = "https://\(appSettings.baseDomain)"
        
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
                       let slidersData = props["sliders"] as? [[String: Any]] {
                        DispatchQueue.main.async {
                            self.sliders = slidersData.compactMap { sliderDict -> Slider? in
                                guard let label = sliderDict["label"] as? String,
                                      let titlesData = sliderDict["titles"] as? [[String: Any]] else {
                                          return nil
                                      }
                                let titles: [SearchResult] = titlesData.compactMap { titleDict in
                                    guard let name = titleDict["name"] as? String,
                                          let id = titleDict["id"] as? Int,
                                          let slug = titleDict["slug"] as? String,
                                          let images = titleDict["images"] as? [[String: Any]],
                                          let poster = images.first(where: { $0["type"] as? String == "poster" }),
                                          let imageUrl = poster["filename"] as? String else {
                                              return nil
                                          }
                                    let href = "https://\(appSettings.baseDomain)/titles/\(id)-\(slug)"
                                    return SearchResult(name: name, imageUrl: "https://cdn.\(appSettings.baseDomain)/images/\(imageUrl)", href: href)
                                }
                                return Slider(label: label, titles: titles)
                            }
                            self.isLoading = false
                            self.isRefreshing = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error fetching or parsing data: \(error)")
                    self.isLoading = false
                    self.isRefreshing = false
                }
            }
        }
    }
}

struct Slider: Identifiable {
    let id = UUID()
    let label: String
    let titles: [SearchResult]
}

struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State private var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    EmptyView()
                }
                Spacer()
            }
        }
        .padding(.top, -50)
    }
}

@main
struct IridumApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var libraryViewModel = LibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .environmentObject(appSettings)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .accentColor(appSettings.accentColor)
                
                LibraryView()
                    .environmentObject(appSettings)
                    .environmentObject(libraryViewModel)
                    .tabItem {
                        Label("Library", systemImage: "book")
                    }
                    .accentColor(appSettings.accentColor)
                
                SearchView()
                    .environmentObject(appSettings)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .accentColor(appSettings.accentColor)
                
                SettingsView()
                    .environmentObject(appSettings)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .accentColor(appSettings.accentColor)
            }
            .environmentObject(appSettings)
            .environmentObject(libraryViewModel)
            .tint(appSettings.accentColor)
            .accentColor(appSettings.accentColor)
        }
    }
}