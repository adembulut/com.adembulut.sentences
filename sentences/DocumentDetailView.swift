//
//  DocumentDetailView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let document: Document
    @State private var showingHistory = false
    @State private var showingEdit = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.fileName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(document.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(document.type == .items ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                            .foregroundColor(document.type == .items ? .blue : .green)
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Created: \(document.createdAt, format: .dateTime.hour().minute().day().month().year())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Updated: \(document.lastUpdatedAt, format: .dateTime.hour().minute().day().month().year())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    if document.type == .items {
                        // Items view
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sentences")
                                .font(.headline)
                            
                            if let sentences = document.sentenceList, !sentences.isEmpty {
                                ForEach(sentences.sorted(by: { $0.order < $1.order }), id: \.id) { sentence in
                                    HStack(alignment: .top) {
                                        Text("\(sentence.order + 1).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 20, alignment: .leading)
                                        
                                        Text(sentence.text)
                                            .font(.body)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            } else {
                                Text("No sentences added yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    } else {
                        // Free text view
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content")
                                .font(.headline)
                            
                            if let freeText = document.freeText, !freeText.isEmpty {
                                Text(freeText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("No content added yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: { showingEdit = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { showingHistory = true }) {
                        HStack {
                            Image(systemName: "clock")
                            Text("History")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Document Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            DocumentEditView(document: document)
        }
        .sheet(isPresented: $showingHistory) {
            DocumentHistoryView(document: document)
        }
    }
}

#Preview {
    let document = Document(fileName: "2025-10-25_01", type: .items)
    return DocumentDetailView(document: document)
        .modelContainer(for: Document.self, inMemory: true)
}
