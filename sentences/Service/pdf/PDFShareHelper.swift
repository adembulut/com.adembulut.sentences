//
//  PDFShareHelper.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - PDF Share Helper
class PDFShareHelper: ObservableObject {
    @Published var isGeneratingPDF = false
    @Published var showingShareSheet = false
    @Published var pdfURL: URL?
    @Published var errorMessage: String?
    
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
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pdfData = PDFGenerator.generatePDF(from: document) else {
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    self.errorMessage = "Failed to generate PDF"
                }
                return
            }
            
            // Create a unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let sanitizedFileName = self.sanitizeFileName(document.fileName)
            let fileName = "\(sanitizedFileName)_\(timestamp).pdf"
            
            // Save to Documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            var pdfURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: pdfURL.path) {
                    try FileManager.default.removeItem(at: pdfURL)
                }
                
                // Write PDF data
                try pdfData.write(to: pdfURL)
                
                // Set file attributes
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
                    self.errorMessage = "Failed to save PDF: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cleanup() {
        if let pdfURL = pdfURL {
            // Delay cleanup to allow sharing to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                try? FileManager.default.removeItem(at: pdfURL)
                self.pdfURL = nil
            }
        }
    }
    
    func sharePDF() {
        guard let pdfURL = pdfURL else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        
        // Exclude problematic activities
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .markupAsPDF
        ]
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
            }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(activityViewController, animated: true) {
                // Clean up after presentation
                self.cleanup()
            }
        }
    }
}

// MARK: - Enhanced Share Sheet
struct EnhancedShareSheet: View {
    let pdfURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if showingError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Share Error")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            showingError = false
                            sharePDF()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("PDF Ready to Share")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your document has been converted to PDF and is ready to share.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Share PDF") {
                            sharePDF()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .navigationTitle("Share PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            sharePDF()
        }
    }
    
    private func sharePDF() {
        let activityViewController = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        
        // Exclude problematic activities
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .markupAsPDF
        ]
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
            }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Add completion handler
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            } else if completed {
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
        }
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(activityViewController, animated: true)
        }
    }
}
