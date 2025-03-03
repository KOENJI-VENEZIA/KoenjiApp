//
//  CompactFilterPopover.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/3/25.
//


import SwiftUI

struct CompactFilterPopover: View {
    @EnvironmentObject var env: AppDependencies
    @Binding var isPresented: Bool
    @Binding var refreshID: UUID
    
    @State private var selectedTab = 0
    
    private let groupOptionConfig: [(GroupOption, String, Color)] = [
        (.none, "list.bullet", .gray),
        (.table, "tablecells", .accentColor),
        (.day, "calendar.day.timeline.left", .accentColor),
        (.week, "calendar.badge.clock", .accentColor),
        (.month, "calendar", .accentColor)
    ]
    
    private let sortOptionConfig: [(SortOption, String, Color)] = [
        (.alphabetically, "textformat.abc", .accentColor),
        (.chronologically, "clock", .accentColor),
        (.byNumberOfPeople, "person.2", .accentColor),
        (.removeSorting, "arrow.up.arrow.down.circle", .gray),
        (.byCreationDate, "plus.circle.fill", .accentColor)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack {
                TabButton(title: "Group", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Sort", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Filters", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider().padding(.vertical, 8)
            
            // Tab content
            VStack {
                switch selectedTab {
                case 0: // Group
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Group By").font(.headline)
                        
                        ForEach(groupOptionConfig, id: \.0) { option, icon, color in
                            Button {
                                env.listView.groupOption = option
                                refreshID = UUID()
                            } label: {
                                HStack {
                                    Text(option.localized)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if env.listView.groupOption == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    
                case 1: // Sort
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sort By").font(.headline)
                        
                        ForEach(sortOptionConfig, id: \.0) { option, icon, color in
                            Button {
                                env.listView.sortOption = option
                                refreshID = UUID()
                            } label: {
                                HStack {
                                    Text(option.localized)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if env.listView.sortOption == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    
                case 2: // Filters
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 16) {
                            // People filter
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Filter by People").font(.headline)
                                
                                Stepper("Number of People: \(env.listView.filterPeople)", 
                                       value: $env.listView.filterPeople, in: 1...20)
                                
                                Toggle("Enable Filter", isOn: $env.listView.hasSelectedPeople)
                                    .onChange(of: env.listView.hasSelectedPeople) { _, newValue in
                                        if newValue {
                                            env.listView.updatePeopleFilter()
                                            refreshID = UUID()
                                        } else {
                                            env.listView.selectedFilters.remove(.people)
                                            refreshID = UUID()
                                        }
                                    }
                            }
                            
                            Divider()
                            
                            // Date filter
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Filter by Date Range").font(.headline)
                                
                                DatePicker("Start Date", 
                                          selection: $env.listView.filterStartDate,
                                          displayedComponents: [.date])
                                
                                DatePicker("End Date", 
                                          selection: $env.listView.filterEndDate,
                                          displayedComponents: [.date])
                                
                                Toggle("Enable Filter", isOn: $env.listView.hasSelectedStartDate)
                                    .onChange(of: env.listView.hasSelectedStartDate) { _, newValue in
                                        env.listView.hasSelectedEndDate = newValue
                                        if newValue {
                                            env.listView.updateDateFilter()
                                            refreshID = UUID()
                                        } else {
                                            env.listView.selectedFilters.remove(.date)
                                            refreshID = UUID()
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                default:
                    EmptyView()
                }
            }
            
            Divider()
            
            // Done button
            Button("Done") {
                isPresented = false
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
        .frame(width: 300, height: 400)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

// Helper view for tabs
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
