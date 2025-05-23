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
    @AppStorage("showDirector") private var showDirector = false
    @AppStorage("showCast") private var showCast = false
    @AppStorage("patchStream") private var patchStream = false
    @AppStorage("holdSpeedPlayer") private var holdSpeedPlayer: Double = 2.0
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Network"), footer: Text("Insert the StreamingUnity URL, and don't add the 'https://' in front of the url nor anything after the domain. Thanks")) {
                    TextField("Base Domain", text: $appSettings.baseDomain)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: Binding(
                        get: { appSettings.accentColor },
                        set: { appSettings.accentColor = $0 }
                    ))
                }
                
                Section(header: Text("Informations")) {
                    Toggle("Show Original Title", isOn: $showOriginalTitle)
                    Toggle("Show Cast", isOn: $showCast)
                    Toggle("Show Director", isOn: $showDirector)
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
                Section(header: Text("Debug")) {
                    Toggle("Stream Patcher", isOn: $patchStream)
                    
                    NavigationLink(destination: SettingsLogsView()) {
                        Text("Logs")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("accentColor") var accentColorData: Data?
    @AppStorage("baseDomain") var _baseDomain: String = "Insert url here."
    
    var baseDomain: String {
        get {
            return _baseDomain
        }
        set {
            var processedValue = newValue
            if processedValue.lowercased().hasPrefix("https://") {
                processedValue = String(processedValue.dropFirst(8))
            }
            if processedValue.hasSuffix("/") {
                processedValue = String(processedValue.dropLast())
            }
            _baseDomain = processedValue
        }
    }
    
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
