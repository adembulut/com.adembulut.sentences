//
//  Item.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import Foundation
import SwiftData

// MARK: - Document Types
enum DocumentType: String, CaseIterable, Codable {
    case items = "items"
    case freeText = "freeText"
    
    var displayName: String {
        switch self {
        case .items: return "Items"
        case .freeText: return "Free Text"
        }
    }
}

// MARK: - History Actions
enum HistoryAction: String, CaseIterable, Codable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        }
    }
}

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
    
    // Different content based on type
    var sentenceList: [Sentence]?
    var freeText: String?
    
    var history: [DocumentHistory]
    
    init(fileName: String, type: DocumentType, createdBy: String = "username") {
        self.id = UUID()
        self.fileName = fileName
        self.type = type
        self.createdAt = Date()
        self.createdBy = createdBy
        self.lastUpdatedAt = Date()
        self.updatedBy = createdBy
        self.history = []
        
        if type == .items {
            self.sentenceList = []
        } else {
            self.freeText = ""
        }
    }
}

// MARK: - Sentence Model
@Model
final class Sentence {
    var id: UUID
    var text: String
    var createdAt: Date
    var order: Int
    var document: Document?
    
    init(text: String, order: Int) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.order = order
    }
}

// MARK: - Document History Model
@Model
final class DocumentHistory {
    var id: UUID
    var documentId: UUID
    var action: HistoryAction
    var changedAt: Date
    var changedBy: String
    var previousData: String?
    var newData: String?
    var changeDescription: String
    var document: Document?
    
    init(documentId: UUID, action: HistoryAction, changedBy: String, changeDescription: String, previousData: String? = nil, newData: String? = nil) {
        self.id = UUID()
        self.documentId = documentId
        self.action = action
        self.changedAt = Date()
        self.changedBy = changedBy
        self.changeDescription = changeDescription
        self.previousData = previousData
        self.newData = newData
    }
}
