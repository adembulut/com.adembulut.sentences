//
//  Document.swift
//  sentences
//
//  Created by adem bulut on 28.10.2025.
//
import Foundation
import SwiftData


// MARK: - Document Model
@Model
final class Document {
    var id: UUID
    var fileName: String
    var type: DocumentType
    var createdAt: Date
    var createdBy: String
    var lastUpdatedAt: Date
    var updatedBy: String
    
    // One-to-many relationship
    @Relationship(deleteRule: .cascade) var sentences: [Sentence]
    
    // Free text for non-items type
    var freeText: String?

    init(fileName: String, type: DocumentType, createdBy: String = "adem.bulut") {
        self.id = UUID()
        self.fileName = fileName
        self.type = type
        self.createdAt = Date()
        self.createdBy = createdBy
        self.lastUpdatedAt = Date()
        self.updatedBy = createdBy
        self.sentences = []

        if type != .items {
            self.freeText = ""
        }
    }
}
