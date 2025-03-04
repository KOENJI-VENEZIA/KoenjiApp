//
//  EmojiSmallPicker.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//
import SwiftUI

struct EmojiSmallPicker: View {
    let onEmojiSelected: (String) -> Void
    @Binding var showFullEmojiPicker: Bool
    @Binding var selectedEmoji: String
    private let emojis = ["❤️", "😂", "😮", "😢", "🙏", "❗️"]

    var body: some View {
        HStack {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    onEmojiSelected(emoji)
                } label: {
                    Text(emoji)
                        .font(.title)
                }
            }

            Button {
                onEmojiSelected("")
                showFullEmojiPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .presentationDetents([.height(50.0)])  // Bottom sheet size
        .presentationDragIndicator(.visible)  // Optional drag indicator
    }
}
