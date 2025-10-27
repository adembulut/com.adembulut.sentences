//
//  sentencesApp.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

@main
struct sentencesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            Sentence.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Perform data migration on app launch
            DataMigrationManager.performMigrationIfNeeded()
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
