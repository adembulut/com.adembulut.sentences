//
//  DocumentHistoryView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let document: Document
    @State private var selectedHistoryItem: DocumentHistory?
    
    var sortedHistory: [DocumentHistory] {
        document.history.sorted { $0.changedAt > $1.changedAt }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if sortedHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This document has no change history yet")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedHistory, id: \.id) { historyItem in
                            HistoryRowView(historyItem: historyItem)
                                .onTapGesture {
                                    selectedHistoryItem = historyItem
                                }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedHistoryItem) { historyItem in
                HistoryDetailView(historyItem: historyItem)
            }
        }
    }
}

struct HistoryRowView: View {
    let historyItem: DocumentHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(historyItem.action.displayName)
                    .font(.headline)
                    .foregroundColor(actionColor)
                
                Spacer()
                
                Text(historyItem.changedAt, format: .dateTime.hour().minute().day().month().year())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(historyItem.changeDescription)
                .font(.body)
                .foregroundColor(.primary)
            
            HStack {
                Text("By: \(historyItem.changedBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if historyItem.previousData != nil || historyItem.newData != nil {
                    Text("Tap to view changes")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var actionColor: Color {
        switch historyItem.action {
        case .created:
            return .green
        case .updated:
            return .blue
        case .deleted:
            return .red
        }
    }
}

struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let historyItem: DocumentHistory
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(historyItem.action.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(actionColor)
                        
                        Text(historyItem.changeDescription)
                            .font(.body)
                        
                        HStack {
                            Text("By: \(historyItem.changedBy)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(historyItem.changedAt, format: .dateTime.hour().minute().day().month().year())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Changes
                    if let previousData = historyItem.previousData, let newData = historyItem.newData {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Changes")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Previous Version")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                
                                Text(formatJSONData(previousData))
                                    .font(.caption)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("New Version")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                
                                Text(formatJSONData(newData))
                                    .font(.caption)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No detailed changes available")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("History Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var actionColor: Color {
        switch historyItem.action {
        case .created:
            return .green
        case .updated:
            return .blue
        case .deleted:
            return .red
        }
    }
    
    private func formatJSONData(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }
}

#Preview {
    let document = Document(fileName: "2025-10-25_01", type: .items)
    return DocumentHistoryView(document: document)
        .modelContainer(for: Document.self, inMemory: true)
}
