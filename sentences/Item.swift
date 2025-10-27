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
    
    init(fileName: String, type: DocumentType, createdBy: String = "adem.bulut") {
        self.id = UUID()
        self.fileName = fileName
        self.type = type
        self.createdAt = Date()
        self.createdBy = createdBy
        self.lastUpdatedAt = Date()
        self.updatedBy = createdBy
        
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

