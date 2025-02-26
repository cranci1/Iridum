//
//  Logger.swift
//  Iridum
//
//  Created by Francesco on 26/02/25.
//

import SwiftUI

struct SettingsLogsView: View {
    @State private var logs: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                Text(logs)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Logs")
            .onAppear {
                logs = Logger.shared.getLogs()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        UIPasteboard.general.string = logs
                    }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive, action: {
                        Logger.shared.clearLogs()
                        logs = Logger.shared.getLogs()
                    }) {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
}

class Logger {
    static let shared = Logger()
    private var logs: [(message: String, timestamp: Date)] = []
    
    private init() {}
    
    func log(_ message: String) {
        logs.append((message: message, timestamp: Date()))
    }
    
    func getLogs() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return logs.map { "[\(dateFormatter.string(from: $0.timestamp))] \($0.message)" }
        .joined(separator: "\n---\n")
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}
