//
//  DocumentRepository.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol
protocol DocumentRepositoryProtocol {
    func fetchAllDocuments() -> [Document]
    func fetchDocumentsByDate(_ date: Date) -> [Document]
    func fetchDocument(by id: UUID) -> Document?
    func createDocument(_ document: Document)
    func updateDocument(_ document: Document)
    func deleteDocument(_ document: Document)
    func isFileNameUnique(_ fileName: String, excluding documentId: UUID?) -> Bool
}

// MARK: - Document Repository
class DocumentRepository: DocumentRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    func fetchAllDocuments() -> [Document] {
        let request = FetchDescriptor<Document>()
        return (try? modelContext.fetch(request)) ?? []
    }
    
    func fetchDocumentsByDate(_ date: Date) -> [Document] {
        let today = Calendar.current.startOfDay(for: date)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<Document> { document in
            document.createdAt >= today && document.createdAt < tomorrow
        }
        
        let request = FetchDescriptor<Document>(predicate: predicate)
        return (try? modelContext.fetch(request)) ?? []
    }
    
    func fetchDocument(by id: UUID) -> Document? {
        let predicate = #Predicate<Document> { document in
            document.id == id
        }
        
        let request = FetchDescriptor<Document>(predicate: predicate)
        return try? modelContext.fetch(request).first
    }
    
    // MARK: - Create Operations
    func createDocument(_ document: Document) {
        modelContext.insert(document)
    }
    
    // MARK: - Update Operations
    func updateDocument(_ document: Document) {
        // Document is already in context, just save
        try? modelContext.save()
    }
    
    // MARK: - Delete Operations
    func deleteDocument(_ document: Document) {
        modelContext.delete(document)
    }
    
    // MARK: - Validation Operations
    func isFileNameUnique(_ fileName: String, excluding documentId: UUID? = nil) -> Bool {
        let request = FetchDescriptor<Document>()
        let allDocuments = (try? modelContext.fetch(request)) ?? []
        
        let documentsWithSameName = allDocuments.filter { $0.fileName == fileName }
        
        if let documentId = documentId {
            // Exclude current document in edit mode
            let otherDocumentsWithSameName = documentsWithSameName.filter { $0.id != documentId }
            return otherDocumentsWithSameName.isEmpty
        }
        
        // No document with same name should exist in create mode
        return documentsWithSameName.isEmpty
    }
}

// MARK: - Mock Repository for Testing
class MockDocumentRepository: DocumentRepositoryProtocol {
    private var documents: [Document] = []
    
    func fetchAllDocuments() -> [Document] {
        return documents
    }
    
    func fetchDocumentsByDate(_ date: Date) -> [Document] {
        let today = Calendar.current.startOfDay(for: date)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return documents.filter { document in
            document.createdAt >= today && document.createdAt < tomorrow
        }
    }
    
    func fetchDocument(by id: UUID) -> Document? {
        return documents.first { $0.id == id }
    }
    
    func createDocument(_ document: Document) {
        documents.append(document)
    }
    
    func updateDocument(_ document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
        }
    }
    
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }
    
    func isFileNameUnique(_ fileName: String, excluding documentId: UUID? = nil) -> Bool {
        let documentsWithSameName = documents.filter { $0.fileName == fileName }
        
        if let documentId = documentId {
            let otherDocumentsWithSameName = documentsWithSameName.filter { $0.id != documentId }
            return otherDocumentsWithSameName.isEmpty
        }
        
        return documentsWithSameName.isEmpty
    }
}
