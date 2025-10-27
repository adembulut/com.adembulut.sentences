//
//  DocumentType.swift
//  sentences
//
//  Created by adem bulut on 28.10.2025.
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
