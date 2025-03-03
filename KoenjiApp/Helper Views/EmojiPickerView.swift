//
//  EmojiPickerView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//


import SwiftUI

struct EmojiHelper {
    static let allEmojis: [String] = {
        let ranges: [ClosedRange<Int>] = [
            0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc symbols and pictographs
            0x1F680...0x1F6FF, // Transport and map symbols
            0x1F1E6...0x1F1FF, // Flags
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0x1F900...0x1F9FF, // Supplemental symbols and pictographs
            0x1FA70...0x1FAFF  // Symbols for additional emoji
        ]
        
        return ranges.flatMap { range in
            range.compactMap { scalar in
                guard let scalarValue = UnicodeScalar(scalar) else { return nil }
                return String(scalarValue)
            }
        }
    }()
}

struct EmojiPickerMenuView: View {
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool // To control the presentation of the bottom sheet
    @State private var searchText: String = ""

    // Generate all possible emojis
    var filteredEmojis: [String] {
        if searchText.isEmpty {
            return EmojiHelper.allEmojis
        } else {
            return EmojiHelper.allEmojis.filter { $0.contains(searchText) }
        }
    }

    var body: some View {
        VStack {
            // Search Bar for Filtering
            TextField("Search Emoji", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Emoji Grid inside the Menu
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                    ForEach(filteredEmojis.prefix(50), id: \.self) { emoji in // Limiting display to avoid overflow
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                        }
                    }
                }
            }
            .frame(height: 200) // Adjust as needed
        }
        .padding()
        .presentationDetents([.medium]) // Bottom sheet size
        .presentationDragIndicator(.visible)   // Optional drag indicator
    }
}
