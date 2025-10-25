//
//  DocumentsListView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentsListView: View {
    @State private var documents: [Document] = []
    @State private var showingNewDocument = false
    @State private var selectedDocument: Document?
    @StateObject private var pdfShareHelper = PDFShareHelper()
    
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
                            DocumentRowView(document: document)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDocument = document
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
                DocumentEditView(repository: repository) {
                    // Callback when document is saved - reload the list
                    loadDocuments()
                }
            }
            .sheet(item: $selectedDocument) { document in
                NavigationView {
                    DocumentDetailView(document: document, repository: repository)
                }
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
            .onAppear {
                loadDocuments()
            }
        }
    }
    
    private func loadDocuments() {
        documents = repository.fetchAllDocuments()
    }
    
    private func deleteDocument(_ document: Document) {
        print("🗑️ Delete button tapped for document: \(document.fileName)")
        
        withAnimation {
            repository.deleteDocument(document)
            // Remove from local array to update UI immediately
            documents.removeAll { $0.id == document.id }
            print("🗑️ Document deleted via repository")
        }
    }
    
    private func shareDocumentAsPDF(_ document: Document) {
        pdfShareHelper.generateAndSharePDF(from: document)
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
