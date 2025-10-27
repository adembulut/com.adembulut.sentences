//
//  ContentView.swift
//  sentences
//
//  Created by adem bulut on 24.10.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "doc.text")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Sentences App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Manage your sentences and paragraphs")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                NavigationLink(destination: DocumentsListView()) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Sentences")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Document.self, inMemory: true)
}
