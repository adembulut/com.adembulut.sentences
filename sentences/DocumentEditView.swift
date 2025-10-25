//
//  DocumentEditView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let document: Document?
    private let repository: DocumentRepositoryProtocol
    
    @State private var fileName: String = ""
    @State private var selectedType: DocumentType = .items
    @State private var freeText: String = ""
    @State private var sentences: [SentenceItem] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isEditing = false
    @FocusState private var focusedSentenceIndex: Int?
    
    init(document: Document? = nil, repository: DocumentRepositoryProtocol? = nil) {
        self.document = document
        self.repository = repository ?? DocumentRepository(modelContext: ModelContext(try! ModelContainer(for: Document.self, Sentence.self, DocumentHistory.self)))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Document Info") {
                    TextField("File Name", text: $fileName)
                        .disabled(isEditing) // File name cannot be changed in edit mode
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .disabled(isEditing) // Type cannot be changed in edit mode
                }
                
                if selectedType == .items {
                    Section("Sentences") {
                        ForEach(sentences.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                TextField("Sentence \(index + 1)", text: $sentences[index].text, axis: .vertical)
                                    .lineLimit(2...6)
                                    .focused($focusedSentenceIndex, equals: index)
                                    .onSubmit {
                                        // Add new sentence when Enter is pressed
                                        if !sentences[index].text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                                            addNewSentence(at: index)
                                        }
                                    }
                                
                                // Show "Add Another" button for each sentence
                                if !sentences[index].text.isEmpty {
                                    Button("Add Another Sentence") {
                                        addNewSentence(at: index)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .onDelete(perform: deleteSentence)
                    }
                } else {
                    Section("Free Text") {
                        TextField("Enter your text here...", text: $freeText, axis: .vertical)
                            .lineLimit(5...15)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Document" : "New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDocument()
                    }
                    .disabled(fileName.isEmpty || (!isValidContent()))
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                setupInitialState()
            }
        }
    }
    
    private func setupInitialState() {
        if let document = document {
            // Edit mode
            isEditing = true
            fileName = document.fileName
            selectedType = document.type
            
            if document.type == .items {
                sentences = document.sentenceList?.map { SentenceItem(text: $0.text, order: $0.order) } ?? []
                if sentences.isEmpty {
                    sentences = [SentenceItem(text: "", order: 0)]
                }
            } else {
                freeText = document.freeText ?? ""
            }
        } else {
            // New document mode
            isEditing = false
            fileName = generateDefaultFileName()
            sentences = [SentenceItem(text: "", order: 0)]
        }
    }
    
    private func generateDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // Check how many documents exist on the same day using repository
        let todayDocuments = repository.fetchDocumentsByDate(Date())
        let count = todayDocuments.count + 1
        return "\(dateString)_\(String(format: "%02d", count))"
    }
    
    private func addNewSentence(at index: Int) {
        // Add new sentence above the specified index
        let newOrder = sentences.isEmpty ? 0 : (sentences.map { $0.order }.max() ?? 0) + 1
        let newSentence = SentenceItem(text: "", order: newOrder)
        
        // Insert at the specified index
        sentences.insert(newSentence, at: index)
        
        // Focus on the newly added sentence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedSentenceIndex = index
        }
    }
    
    private func deleteSentence(at offsets: IndexSet) {
        sentences.remove(atOffsets: offsets)
        
        // Reorder the remaining sentences
        for (index, _) in sentences.enumerated() {
            sentences[index].order = index
        }
    }
    
    private func isValidContent() -> Bool {
        if selectedType == .items {
            // At least one non-empty sentence is required
            let hasValidSentences = sentences.contains { !$0.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty }
            return hasValidSentences
        } else {
            return !freeText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
        }
    }
    
    private func saveDocument() {
        // File name validation
        if !isValidFileName() {
            if isEditing {
                alertMessage = "A document with this name already exists. Please choose a different name."
            } else {
                alertMessage = "A document with this name already exists. Please choose a different name."
            }
            showingAlert = true
            return
        }
        
        if let document = document {
            // Edit mode
            updateDocument(document)
        } else {
            // New document mode
            createNewDocument()
        }
        
        dismiss()
    }
    
    private func isValidFileName() -> Bool {
        // Use repository to check file name uniqueness
        let documentId = isEditing ? document?.id : nil
        return repository.isFileNameUnique(fileName, excluding: documentId)
    }
    
    private func createNewDocument() {
        let newDocument = Document(fileName: fileName, type: selectedType)
        
        if selectedType == .items {
            // Filter empty sentences and reorder
            let filteredSentences: [SentenceItem] = sentences.compactMap { sentenceItem in
                let trimmedText = sentenceItem.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedText.isEmpty else { return nil }
                return sentenceItem
            }
            
            // Reorder the sentences
            newDocument.sentenceList = filteredSentences.enumerated().compactMap { (index, sentenceItem) in
                let sentence = Sentence(text: sentenceItem.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), order: index)
                sentence.document = newDocument
                return sentence
            }
        } else {
            newDocument.freeText = freeText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        // Add history record
        let history = DocumentHistory(
            documentId: newDocument.id,
            action: .created,
            changedBy: "adem.bulut",
            changeDescription: "Document created"
        )
        newDocument.history.append(history)
        
        // Use repository to create document
        repository.createDocument(newDocument)
    }
    
    private func updateDocument(_ document: Document) {
        let previousData = getDocumentDataAsJSON(document)
        
        document.lastUpdatedAt = Date()
        document.updatedBy = "adem.bulut"
        
        if selectedType == .items {
            // Smart sentence update strategy
            updateSentencesForDocument(document)
        } else {
            document.freeText = freeText
        }
        
        // Add history record
        let newData = getDocumentDataAsJSON(document)
        let history = DocumentHistory(
            documentId: document.id,
            action: .updated,
            changedBy: "adem.bulut",
            changeDescription: "Document updated",
            previousData: previousData,
            newData: newData
        )
        document.history.append(history)
        
        // Use repository to update document
        repository.updateDocument(document)
    }
    
    private func updateSentencesForDocument(_ document: Document) {
        // First filter empty sentences
        let filteredSentences: [SentenceItem] = sentences.compactMap { sentenceItem in
            let trimmedText = sentenceItem.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return nil }
            return sentenceItem
        }
        
        // Clear existing sentences (they will be replaced by new ones)
        document.sentenceList?.removeAll()
        
        // Add filtered sentences (reorder)
        document.sentenceList = filteredSentences.enumerated().compactMap { (index, sentenceItem) in
            let sentence = Sentence(text: sentenceItem.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), order: index)
            sentence.document = document
            return sentence
        }
    }
    
    private func getDocumentDataAsJSON(_ document: Document) -> String {
        let data: [String: Any] = [
            "type": document.type.rawValue,
            "freeText": document.freeText ?? "",
            "sentenceCount": document.sentenceList?.count ?? 0
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return ""
    }
}

struct SentenceItem: Identifiable {
    let id = UUID()
    var text: String
    var order: Int
}

#Preview {
    DocumentEditView()
        .modelContainer(for: Document.self, inMemory: true)
}
