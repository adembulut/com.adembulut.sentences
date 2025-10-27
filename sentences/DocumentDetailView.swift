//
//  DocumentDetailView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    let document: Document
    private let repository: DocumentRepositoryProtocol
    @State private var showingHistory = false
    @State private var showingEdit = false
    @StateObject private var pdfShareHelper = PDFShareHelper()
    @State private var searchText = ""
    
    init(document: Document, repository: DocumentRepositoryProtocol? = nil) {
        self.document = document
        self.repository = repository ?? DocumentRepository(modelContext: ModelContext(try! ModelContainer(for: Document.self, Sentence.self, DocumentHistory.self)))
    }
    
    // Filter sentences based on search text
    private var filteredSentences: [Sentence] {
        guard let sentences = document.sentenceList else { return [] }
        
        if searchText.isEmpty {
            return sentences.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        let lowercasedSearch = searchText.lowercased()
        return sentences.filter { sentence in
            sentence.text.lowercased().contains(lowercasedSearch)
        }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
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
                
                // Search bar (only for items type)
                if document.type == .items {
                    SearchTextField(text: $searchText, placeholder: "Search sentences...")
                        .padding(.horizontal)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    if document.type == .items {
                        // Items view
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sentences")
                                .font(.headline)
                            
                            if !filteredSentences.isEmpty {
                                ForEach(Array(filteredSentences.enumerated()), id: \.element.id) { index, sentence in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 20, alignment: .leading)
                                        
                                        Text(sentence.text)
                                            .font(.body)
                                            .textSelection(.enabled)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            } else if !searchText.isEmpty {
                                Text("No sentences found")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else if document.sentenceList?.isEmpty ?? true {
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
                                    .textSelection(.enabled)
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
                VStack(spacing: 12) {
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
                    
                    // Share PDF Button
                    Button(action: { pdfShareHelper.generateAndSharePDF(from: document) }) {
                        HStack {
                            if pdfShareHelper.isGeneratingPDF {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(pdfShareHelper.isGeneratingPDF ? "Generating PDF..." : "Share as PDF")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(pdfShareHelper.isGeneratingPDF)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Document Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            DocumentEditView(document: document, repository: repository)
        }
        .sheet(isPresented: $showingHistory) {
            DocumentHistoryView(document: document)
        }
        .sheet(isPresented: $pdfShareHelper.showingShareSheet) {
            if let pdfURL = pdfShareHelper.pdfURL {
                EnhancedShareSheet(pdfURL: pdfURL)
                    .onDisappear {
                        pdfShareHelper.cleanup()
                    }
            }
        }
        .alert("PDF Error", isPresented: .constant(pdfShareHelper.errorMessage != nil)) {
            Button("OK") {
                pdfShareHelper.errorMessage = nil
            }
        } message: {
            if let errorMessage = pdfShareHelper.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    let document = Document(fileName: "2025-10-25_01", type: .items)
    return DocumentDetailView(document: document)
        .modelContainer(for: Document.self, inMemory: true)
}
