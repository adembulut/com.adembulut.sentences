//
//  DocumentsListView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.lastUpdatedAt, order: .reverse) private var documents: [Document]
    @State private var showingNewDocument = false
    @State private var selectedDocument: Document?
    @StateObject private var pdfShareManager = PDFShareManager()
    
    private let repository: DocumentRepositoryProtocol
    
    init(repository: DocumentRepositoryProtocol? = nil) {
        self.repository = repository ?? DocumentRepository(modelContext: ModelContext(try! ModelContainer(for: Document.self, Sentence.self, DocumentHistory.self)))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if documents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Documents Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Tap 'New' to create your first document")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(documents) { document in
                            NavigationLink(destination: DocumentDetailView(document: document)) {
                                DocumentRowView(document: document)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Edit") {
                                    selectedDocument = document
                                }
                                .tint(.blue)
                                
                                Button("Delete") {
                                    deleteDocument(document)
                                }
                                .tint(.red)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button("Share PDF") {
                                    shareDocumentAsPDF(document)
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewDocument = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewDocument) {
                DocumentEditView(repository: repository)
            }
            .sheet(item: $selectedDocument) { document in
                DocumentEditView(document: document, repository: repository)
            }
            .sheet(isPresented: $pdfShareManager.showingShareSheet) {
                if let pdfURL = pdfShareManager.pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                        .onDisappear {
                            pdfShareManager.cleanup()
                        }
                }
            }
        }
    }
    
    private func deleteDocument(_ document: Document) {
        withAnimation {
            // Add history record
            let history = DocumentHistory(
                documentId: document.id,
                action: .deleted,
                changedBy: "username",
                changeDescription: "Document deleted"
            )
            modelContext.insert(history)
            
            // Use repository to delete document
            repository.deleteDocument(document)
        }
    }
    
    private func shareDocumentAsPDF(_ document: Document) {
        pdfShareManager.generateAndSharePDF(from: document)
    }
}

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.createdAt, format: .dateTime.hour().minute().day().month().year())
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(document.fileName)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Text(document.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(document.type == .items ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .foregroundColor(document.type == .items ? .blue : .green)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("Updated: \(document.lastUpdatedAt, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DocumentsListView()
        .modelContainer(for: Document.self, inMemory: true)
}
