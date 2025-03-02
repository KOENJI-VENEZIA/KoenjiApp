import SwiftUI

/// A tag-based menu for sort options that matches the design language
/// of the other filter components
struct SortOptionTag: View {
    @Binding var sortOption: SortOption?
    var onSortChange: (() -> Void)?
    
    // Icon and color mappings for sort options
    private let sortOptionConfig: [(SortOption, String, Color)] = [
        (.alphabetically, "textformat.abc", .accentColor),
        (.chronologically, "clock", .accentColor),
        (.byNumberOfPeople, "person.2", .accentColor),
        (.removeSorting, "arrow.up.arrow.down.circle", .gray)
    ]
    
    var body: some View {
        Menu {
            Text("Ordina per...")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(sortOptionConfig, id: \.0) { option, icon, color in
                Button {
                    sortOption = option
                    onSortChange?()
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(option.rawValue)
                            .foregroundColor(color)
                        if sortOption == option {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(color)
                        }
                    }
                }
            }
        } label: {
            // Tag-style appearance for the toolbar button
            let config = getCurrentSortConfig()
                        HStack(spacing: TagStyle.iconSpacing) {
                            Image(systemName: config.1)
                                .foregroundColor(config.2)
                            Text(config.0.rawValue)
                                .font(TagStyle.font)
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .apply(TagStyle.self, color: config.2)
        }
        .id("SortOptionMenu-\(sortOption?.rawValue ?? "none")") // Add unique ID
    }
    
    func getCurrentSortConfig() -> (SortOption, String, Color) {
        for config in sortOptionConfig {
            if config.0 == sortOption {
                return config
            }
        }
        return sortOptionConfig.last! // Default to removeSorting
    }
}
