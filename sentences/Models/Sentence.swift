//
//  Sentence.swift
//  sentences
//
//  Created by adem bulut on 28.10.2025.
//

import Foundation
import SwiftData

// MARK: - Sentence Model
@Model
final class Sentence {
    var id: UUID
    var text: String
    var createdAt: Date
    var order: Int

    // Relationship to Document
    var document: Document?

    init(text: String, order: Int) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.order = order
    }
}
