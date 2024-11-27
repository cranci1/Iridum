//
//  SettingsView.swift
//  Iridum
//
//  Created by Francesco on 27/11/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("alwaysLandscape") private var isAlwaysLandscape = false
    @AppStorage("showOriginalTitle") private var showOriginalTitle = false
    @AppStorage("holdSpeedPlayer") private var holdSpeedPlayer: Double = 0.5
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: Binding(
                        get: { appSettings.accentColor },
                        set: { appSettings.accentColor = $0 }
                    ))
                }
                
                Section(header: Text("Informations")) {
                    Toggle("Show Original Title", isOn: $showOriginalTitle)
                }
                
                Section(header: Text("Player")) {
                    Toggle("Force Landscape", isOn: $isAlwaysLandscape)
                    
                    HStack {
                        Text("Hold Speed:")
                        Spacer()
                        Stepper(
                            value: $holdSpeedPlayer,
                            in: 0.25...2.0,
                            step: 0.25
                        ) {
                            Text(String(format: "%.2f", holdSpeedPlayer))
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("accentColor") var accentColorData: Data?
    
    var accentColor: Color {
        get {
            guard let data = accentColorData,
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
                return .mint
            }
            return Color(uiColor)
        }
        set {
            let uiColor = UIColor(newValue)
            accentColorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: true)
        }
    }
}

