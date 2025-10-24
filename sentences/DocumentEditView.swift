//
//  DocumentEditView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct DocumentEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let document: Document?
    
    @State private var fileName: String = ""
    @State private var selectedType: DocumentType = .items
    @State private var freeText: String = ""
    @State private var sentences: [SentenceItem] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isEditing = false
    
    init(document: Document? = nil) {
        self.document = document
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Document Info") {
                    TextField("File Name", text: $fileName)
                        .disabled(isEditing) // Düzenleme modunda dosya adı değiştirilemez
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .disabled(isEditing) // Düzenleme modunda type değiştirilemez
                }
                
                if selectedType == .items {
                    Section("Sentences") {
                        ForEach(sentences.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                TextField("Sentence \(index + 1)", text: $sentences[index].text, axis: .vertical)
                                    .lineLimit(2...6)
                                
                                if !sentences[index].text.isEmpty && index == sentences.count - 1 {
                                    Button("Add Another Sentence") {
                                        addNewSentence()
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
            // Düzenleme modu
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
            // Yeni doküman modu
            isEditing = false
            fileName = generateDefaultFileName()
            sentences = [SentenceItem(text: "", order: 0)]
        }
    }
    
    private func generateDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // Aynı gün kaç tane doküman var kontrol et
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<Document> { document in
            document.createdAt >= today && document.createdAt < tomorrow
        }
        
        let request = FetchDescriptor<Document>(predicate: predicate)
        let todayDocuments = (try? modelContext.fetch(request)) ?? []
        
        let count = todayDocuments.count + 1
        return "\(dateString)_\(String(format: "%02d", count))"
    }
    
    private func addNewSentence() {
        let newOrder = sentences.count
        sentences.append(SentenceItem(text: "", order: newOrder))
    }
    
    private func deleteSentence(at offsets: IndexSet) {
        sentences.remove(atOffsets: offsets)
        // Order'ları yeniden düzenle
        for (index, _) in sentences.enumerated() {
            sentences[index].order = index
        }
    }
    
    private func isValidContent() -> Bool {
        if selectedType == .items {
            return !sentences.isEmpty && sentences.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        } else {
            return !freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func saveDocument() {
        // Dosya adı validasyonu
        if !isValidFileName() {
            alertMessage = "A document with this name already exists. Please choose a different name."
            showingAlert = true
            return
        }
        
        if let document = document {
            // Düzenleme modu
            updateDocument(document)
        } else {
            // Yeni doküman modu
            createNewDocument()
        }
        
        dismiss()
    }
    
    private func isValidFileName() -> Bool {
        let predicate = #Predicate<Document> { doc in
            doc.fileName == fileName
        }
        
        let request = FetchDescriptor<Document>(predicate: predicate)
        let existingDocuments = (try? modelContext.fetch(request)) ?? []
        
        // Eğer düzenleme modundaysak, kendi dokümanımızı hariç tut
        if isEditing, let document = document {
            return existingDocuments.allSatisfy { $0.id != document.id }
        }
        
        return existingDocuments.isEmpty
    }
    
    private func createNewDocument() {
        let newDocument = Document(fileName: fileName, type: selectedType)
        
        if selectedType == .items {
            newDocument.sentenceList = sentences.compactMap { sentenceItem in
                guard !sentenceItem.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                let sentence = Sentence(text: sentenceItem.text, order: sentenceItem.order)
                sentence.document = newDocument
                return sentence
            }
        } else {
            newDocument.freeText = freeText
        }
        
        // History kaydı ekle
        let history = DocumentHistory(
            documentId: newDocument.id,
            action: .created,
            changedBy: "username",
            changeDescription: "Document created"
        )
        newDocument.history.append(history)
        
        modelContext.insert(newDocument)
    }
    
    private func updateDocument(_ document: Document) {
        let previousData = getDocumentDataAsJSON(document)
        
        document.lastUpdatedAt = Date()
        document.updatedBy = "username"
        
        if selectedType == .items {
            // Mevcut cümleleri sil
            if let existingSentences = document.sentenceList {
                for sentence in existingSentences {
                    modelContext.delete(sentence)
                }
            }
            
            // Yeni cümleleri ekle
            document.sentenceList = sentences.compactMap { sentenceItem in
                guard !sentenceItem.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                let sentence = Sentence(text: sentenceItem.text, order: sentenceItem.order)
                sentence.document = document
                return sentence
            }
        } else {
            document.freeText = freeText
        }
        
        // History kaydı ekle
        let newData = getDocumentDataAsJSON(document)
        let history = DocumentHistory(
            documentId: document.id,
            action: .updated,
            changedBy: "username",
            changeDescription: "Document updated",
            previousData: previousData,
            newData: newData
        )
        document.history.append(history)
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
