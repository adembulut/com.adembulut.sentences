//
//  SearchTextField.swift
//  sentences
//
//  Created by adem bulut on 27.10.2025.
//

import SwiftUI

struct SearchTextField: View {
    @Binding var searchText: String
    let placeholder: String
    
    init(text: Binding<String>, placeholder: String = "Search...") {
        self._searchText = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        TextField(placeholder, text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .overlay(alignment: .trailing) {
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                    }
                }
            }
    }
}

#Preview {
    @Previewable @State var searchText = ""
    return VStack {
        SearchTextField(text: $searchText, placeholder: "Search sentences...")
            .padding()
    }
}

