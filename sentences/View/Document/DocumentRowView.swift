//
//  DocumentRowView.swift
//  sentences
//
//  Created by adem bulut on 28.10.2025.
//

import SwiftUI

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
    let doc: Document = {
        let d = Document(fileName: "2025-10-10_1", type: .items)
        d.lastUpdatedAt = Date()
        d.createdAt = Date()
        d.updatedBy = "preview_user"
        return d
    }()
    
    DocumentRowView(document: doc)
}
