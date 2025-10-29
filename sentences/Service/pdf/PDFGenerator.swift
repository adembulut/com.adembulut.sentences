//
//  PDFGenerator.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - PDF Generator
class PDFGenerator {
    
    // MARK: - Generate PDF from Document
    static func generatePDF(from document: Document) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Sentences App",
            kCGPDFContextAuthor: document.createdBy,
            kCGPDFContextTitle: document.fileName,
            kCGPDFContextSubject: "Document Export"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // 8.5 inches in points
        let pageHeight = 11.0 * 72.0 // 11 inches in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Add content to PDF
            addDocumentContent(to: context, document: document, pageRect: pageRect)
        }
        
        return pdfData
    }
    
    // MARK: - Add Document Content to PDF
    private static func addDocumentContent(to context: UIGraphicsPDFRendererContext, document: Document, pageRect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let headerFont = UIFont.boldSystemFont(ofSize: 18)
        let bodyFont = UIFont.systemFont(ofSize: 14)
        let metaFont = UIFont.systemFont(ofSize: 12)
        
        var currentY: CGFloat = 50
        let leftMargin: CGFloat = 50
        let rightMargin: CGFloat = 50
        let contentWidth = pageRect.width - leftMargin - rightMargin
        
        // Document Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleString = NSAttributedString(string: document.fileName, attributes: titleAttributes)
        let titleSize = titleString.size()
        titleString.draw(in: CGRect(x: leftMargin, y: currentY, width: contentWidth, height: titleSize.height))
        currentY += titleSize.height + 20
        
        // Document Metadata
        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: metaFont,
            .foregroundColor: UIColor.gray
        ]
        
        let createdDate = DateFormatter.localizedString(from: document.createdAt, dateStyle: .medium, timeStyle: .short)
        let updatedDate = DateFormatter.localizedString(from: document.lastUpdatedAt, dateStyle: .medium, timeStyle: .short)
        
        let metadataText = """
        Type: \(document.type.displayName)
        Created: \(createdDate) by \(document.createdBy)
        Last Updated: \(updatedDate) by \(document.updatedBy)
        """
        
        let metadataString = NSAttributedString(string: metadataText, attributes: metadataAttributes)
        let metadataSize = metadataString.size()
        metadataString.draw(in: CGRect(x: leftMargin, y: currentY, width: contentWidth, height: metadataSize.height))
        currentY += metadataSize.height + 30
        
        // Content based on document type
        if document.type == .items {
            addSentencesContent(to: context, document: document, startY: &currentY, leftMargin: leftMargin, contentWidth: contentWidth, pageRect: pageRect, headerFont: headerFont, bodyFont: bodyFont)
        } else {
            addFreeTextContent(to: context, document: document, startY: &currentY, leftMargin: leftMargin, contentWidth: contentWidth, pageRect: pageRect, headerFont: headerFont, bodyFont: bodyFont)
        }
    }
    
    // MARK: - Add Sentences Content
    private static func addSentencesContent(to context: UIGraphicsPDFRendererContext, document: Document, startY: inout CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageRect: CGRect, headerFont: UIFont, bodyFont: UIFont) {
        let sentences = document.sentences
        guard !sentences.isEmpty else {
            addEmptyContentMessage(to: context, startY: &startY, leftMargin: leftMargin, contentWidth: contentWidth, pageRect: pageRect, headerFont: headerFont, bodyFont: bodyFont)
            return
        }
        
        // Sentences Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        
        let headerString = NSAttributedString(string: "Sentences", attributes: headerAttributes)
        let headerSize = headerString.size()
        headerString.draw(in: CGRect(x: leftMargin, y: startY, width: contentWidth, height: headerSize.height))
        startY += headerSize.height + 15
        
        // Add each sentence
        let sortedSentences = sentences.sorted { $0.order < $1.order }
        
        for (index, sentence) in sortedSentences.enumerated() {
            // Check if we need a new page
            if startY > pageRect.height - 100 {
                context.beginPage()
                startY = 50
            }
            
            // Sentence number and text
            let sentenceAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black
            ]
            
            let sentenceText = "\(index + 1). \(sentence.text)"
            let sentenceString = NSAttributedString(string: sentenceText, attributes: sentenceAttributes)
            
            // Calculate text size for wrapping
            let textSize = sentenceString.boundingRect(
                with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).size
            
            sentenceString.draw(in: CGRect(x: leftMargin, y: startY, width: contentWidth, height: textSize.height))
            startY += textSize.height + 10
        }
    }
    
    // MARK: - Add Free Text Content
    private static func addFreeTextContent(to context: UIGraphicsPDFRendererContext, document: Document, startY: inout CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageRect: CGRect, headerFont: UIFont, bodyFont: UIFont) {
        guard let freeText = document.freeText, !freeText.isEmpty else {
            addEmptyContentMessage(to: context, startY: &startY, leftMargin: leftMargin, contentWidth: contentWidth, pageRect: pageRect, headerFont: headerFont, bodyFont: bodyFont)
            return
        }
        
        // Content Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        
        let headerString = NSAttributedString(string: "Content", attributes: headerAttributes)
        let headerSize = headerString.size()
        headerString.draw(in: CGRect(x: leftMargin, y: startY, width: contentWidth, height: headerSize.height))
        startY += headerSize.height + 15
        
        // Free text content
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black
        ]
        
        let textString = NSAttributedString(string: freeText, attributes: textAttributes)
        
        // Calculate text size for wrapping
        let textSize = textString.boundingRect(
            with: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        textString.draw(in: CGRect(x: leftMargin, y: startY, width: contentWidth, height: textSize.height))
        startY += textSize.height + 20
    }
    
    // MARK: - Add Empty Content Message
    private static func addEmptyContentMessage(to context: UIGraphicsPDFRendererContext, startY: inout CGFloat, leftMargin: CGFloat, contentWidth: CGFloat, pageRect: CGRect, headerFont: UIFont, bodyFont: UIFont) {
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.gray
        ]
        
        let messageString = NSAttributedString(string: "No content available", attributes: messageAttributes)
        let messageSize = messageString.size()
        messageString.draw(in: CGRect(x: leftMargin, y: startY, width: contentWidth, height: messageSize.height))
        startY += messageSize.height + 20
    }
}

// MARK: - PDF Share Manager
class PDFShareManager: ObservableObject {
    @Published var isGeneratingPDF = false
    @Published var showingShareSheet = false
    @Published var pdfURL: URL?
    
    // MARK: - Sanitize File Name
    private func sanitizeFileName(_ fileName: String) -> String {
        // Characters not allowed in file names: / : < > " | ? * and control characters
        let invalidChars = CharacterSet(charactersIn: "/<>:\"|?*").union(.controlCharacters)
        
        // Replace invalid characters with underscore
        var sanitized = fileName
            .components(separatedBy: invalidChars)
            .joined(separator: "_")
        
        // Remove leading/trailing spaces and replace multiple spaces/underscores with single underscore
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        
        // Ensure file name is not empty
        if sanitized.isEmpty {
            sanitized = "document"
        }
        
        // Limit length to 200 characters to avoid filesystem issues
        if sanitized.count > 200 {
            let index = sanitized.index(sanitized.startIndex, offsetBy: 200)
            sanitized = String(sanitized[..<index])
        }
        
        return sanitized
    }
    
    func generateAndSharePDF(from document: Document) {
        isGeneratingPDF = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pdfData = PDFGenerator.generatePDF(from: document) else {
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                }
                return
            }
            
            // Save PDF to Documents directory instead of temp
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let sanitizedFileName = self.sanitizeFileName(document.fileName)
            let fileName = "\(sanitizedFileName)_\(Date().timeIntervalSince1970).pdf"
            var pdfURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try pdfData.write(to: pdfURL)
                
                // Set proper file attributes
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try pdfURL.setResourceValues(resourceValues)
                
                DispatchQueue.main.async {
                    self.pdfURL = pdfURL
                    self.isGeneratingPDF = false
                    self.showingShareSheet = true
                }
            } catch {
                print("Error saving PDF: \(error)")
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                }
            }
        }
    }
    
    func cleanup() {
        if let pdfURL = pdfURL {
            try? FileManager.default.removeItem(at: pdfURL)
            self.pdfURL = nil
        }
    }
}
