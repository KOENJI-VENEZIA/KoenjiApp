import SwiftUI

/// A tag-based menu for grouping options that matches the design language
/// of the other filter components
struct GroupOptionTag: View {
    @Binding var groupOption: GroupOption
    @Binding var sortOption: SortOption?
    var onGroupChange: (() -> Void)?
    
    // Icon and color mappings for group options
    private let groupOptionConfig: [(GroupOption, String, Color)] = [
        (.none, "list.bullet", .gray),
        (.table, "tablecells", .accentColor),
        (.day, "calendar.day.timeline.left", .accentColor),
        (.week, "calendar.badge.clock", .accentColor),
        (.month, "calendar", .accentColor)
    ]
    
    var body: some View {
        Menu {
            Text("Raggruppa per...")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(groupOptionConfig, id: \.0) { option, icon, color in
                Button {
                    if sortOption == .byCreationDate {
                        groupOption = .none
                    } else {
                        groupOption = option
                    }
                    onGroupChange?()
                } label: {
                    HStack {
                        
                        if groupOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(color)
                        }
                        Text(option.localized)
                            .foregroundColor(color)
                    }
                }
            }
        } label: {
            // Tag-style appearance for the toolbar button
            let config = getCurrentGroupConfig()
                       HStack(spacing: TagStyle.iconSpacing) {
                           Image(systemName: config.1)
                               .foregroundColor(config.2)
                           Text(config.0.localized)
                               .font(TagStyle.font)
                               .lineLimit(1)
                       }
                       .fixedSize(horizontal: true, vertical: false)
                       .apply(TagStyle.self, color: config.2)
        }
    }
    
    private func getCurrentGroupConfig() -> (GroupOption, String, Color) {
        for config in groupOptionConfig {
            if config.0 == groupOption {
                return config
            }
        }
        return groupOptionConfig.first! // Default to .none
    }
}
