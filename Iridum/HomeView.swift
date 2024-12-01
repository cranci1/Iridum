//
//  HomeView.swift
//  Iridum
//
//  Created by Francesco on 25/11/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("Home")
            .font(.largeTitle)
            .padding()
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
