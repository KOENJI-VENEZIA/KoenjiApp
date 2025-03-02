import SwiftUI

/// A filter for reservation states that uses the design language of ReservationInfoCard
struct ReservationStateFilter: View {
    // Remove direct environment object usage, use binding instead
    @Binding var filterOption: Set<FilterOption>
    
    // Callback when state filter changes
    var onFilterChange: (() -> Void)?
    
    // Options to show in the filter with colors matching ReservationInfoCard
    let stateOptions: [(FilterOption, String, String, Color)] = [
        (.none, "Prenotate", "checkmark.circle.fill", Color.green),
        (.canceled, "Cancellate", "xmark.circle.fill", Color.red),
        (.toHandle, "Da gestire", "exclamationmark.circle.fill", Color.orange),
        (.waitingList, "Lista d'attesa", "person.fill.questionmark", Color.gray),
        (.deleted, "Eliminate", "trash.fill", Color.gray)
    ]
    
    var body: some View {
        Menu {
            ForEach(stateOptions, id: \.0) { option, label, icon, color in
                Button(action: {
                    toggleStateFilter(option)
                }) {
                    // Style each menu item like a tag
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(label)
                            .foregroundColor(color)
                            .fontWeight(.semibold)
                    }
                }
            }
        } label: {
            // In the toolbar, just show an icon with appropriate coloring
            let currentState = getCurrentState()
            HStack(spacing: TagStyle.iconSpacing) {
                   Image(systemName: currentState.2)
                       .foregroundColor(currentState.3)
                   Text(currentState.1)
                       .foregroundColor(currentState.3)
                       .font(.caption.weight(.semibold))
                       .lineLimit(1)
               }
            .apply(TagStyle.self, color: currentState.3)
            .fixedSize(horizontal: true, vertical: false)
        }
        
    }
    
    func getCurrentState() -> (FilterOption, String, String, Color) {
        // Check which filter is currently selected
        for option in stateOptions {
            if filterOption.contains(option.0) &&
               option.0 != .people &&
               option.0 != .date {
                return option
            }
        }
        
        // Default to "Attive" if no state filter is selected
        return stateOptions[0]
    }
    
    func toggleStateFilter(_ option: FilterOption) {
        // First, remove all existing state filters
        var newFilters = filterOption
        for stateOption in stateOptions {
            newFilters.remove(stateOption.0)
        }
        
        // Then add the selected one (unless it's .none and was already selected)
        if option != .none || !filterOption.contains(.none) {
            newFilters.insert(option)
        }
        
        // Update filters while preserving other filter types
        filterOption = newFilters
        
        // Call the callback if provided
        onFilterChange?()
    }
}
