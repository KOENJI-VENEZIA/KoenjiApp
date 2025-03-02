import SwiftUI

/// A tag-based menu for additional filters that matches the design language
/// of ReservationStateFilter and ReservationInfoCard
struct OtherFiltersTag: View {
    @EnvironmentObject var env: AppDependencies
    
    // State for popovers
    @Binding var showPeoplePopover: Bool
    @Binding var showStartDatePopover: Bool
    @Binding var showEndDatePopover: Bool
    
    // State for filters
    @Binding var filterPeople: Int
    @Binding var filterStartDate: Date
    @Binding var filterEndDate: Date
    @Binding var selectedFilters: Set<FilterOption>
    // Environment objects
    @EnvironmentObject var appState: AppState
    
    // Callback when filters change
    var onFilterChange: (() -> Void)?
    
    var body: some View {
        Menu {
            Text("Filtri")
                .font(.headline)
                .padding(.bottom, 4)
            
            Button {
                showPeoplePopover = true
            } label: {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.indigo)
                    Text("Numero ospiti")
                    if selectedFilters.contains(.people) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.indigo)
                    }
                }
            }
            
            Button {
                showStartDatePopover = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    if !env.listView.selectedFilters.contains(.date) {
                        Text("Da data...")
                    } else {
                        Text("Dal '\(DateHelper.formatFullDate(filterStartDate))'...")
                        Image(systemName: "checkmark")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Button {
                showEndDatePopover = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    if !env.listView.selectedFilters.contains(.date) {
                        Text("A data...")
                    } else {
                        Text("Al '\(DateHelper.formatFullDate(filterEndDate))'...")
                        Image(systemName: "checkmark")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if hasActiveFilters {
                Divider()
                Button(role: .destructive) {
                    clearFilters()
                } label: {
                    Label("Rimuovi filtri", systemImage: "xmark.circle")
                }
            }
        } label: {
            // Tag-style appearance for the toolbar button
            createTagLabel()
            
        }
        .id("OtherFiltersMenu-\(selectedFilters.hashValue)") // Add unique ID
        .popover(isPresented: $showPeoplePopover) {
            PeoplePickerView(filterPeople: $filterPeople,
                             hasSelectedPeople: $env.listView.hasSelectedPeople)
        }
        .popover(isPresented: $showStartDatePopover) {
            DatePickerView(filteredDate: $filterStartDate,
                           hasSelectedStartDate: $env.listView.hasSelectedStartDate)
            .environmentObject(appState)
                .frame(width: 300)
        }
        .popover(isPresented: $showEndDatePopover) {
            DatePickerView(filteredDate: $filterEndDate,
                           hasSelectedEndDate: $env.listView.hasSelectedEndDate)
            .environmentObject(appState)
                .frame(width: 300)
        }
    }
    
    var hasActiveFilters: Bool {
        selectedFilters.contains(.people) || selectedFilters.contains(.date)
    }
    
    private func createTagLabel() -> some View {
         HStack(spacing: TagStyle.iconSpacing) {
             Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
             Text(hasActiveFilters ? "Filtri attivi" : "Altri filtri")
                 .font(TagStyle.font)
                 .lineLimit(1)
         }
         .fixedSize(horizontal: true, vertical: false)
         .apply(TagStyle.self, color: hasActiveFilters ? .indigo : .gray)
     }
    
    private func clearFilters() {
        var newFilters = selectedFilters
        newFilters.remove(.people)
        newFilters.remove(.date)
        selectedFilters = newFilters
        env.listView.hasSelectedPeople = false
        env.listView.hasSelectedStartDate = false
        env.listView.hasSelectedEndDate = false
        onFilterChange?()
    }
}
