//
//  DatePicker.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var filteredDate: Date
    @Binding var hasSelectedStartDate: Bool
    @Binding var hasSelectedEndDate: Bool
    @EnvironmentObject var appState: AppState
    
    init(filteredDate: Binding<Date> = Binding.constant(Date()), hasSelectedStartDate: Binding<Bool> = Binding.constant(false), hasSelectedEndDate: Binding<Bool> = Binding.constant(false)) {
        self._filteredDate = filteredDate
        self._hasSelectedStartDate = hasSelectedStartDate
        self._hasSelectedEndDate = hasSelectedEndDate
    }
    
    var body: some View {
        
        if hasSelectedStartDate || hasSelectedEndDate {
            DatePicker(
                "",
                selection: $filteredDate,
                displayedComponents: .date
                
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .labelsHidden()
            .onChange(of: filteredDate) {
                hasSelectedStartDate = true
                hasSelectedEndDate = true
            }
        } else {
            DatePicker(
                "",
                selection: $appState.selectedDate,
                displayedComponents: .date
                
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .labelsHidden()
        }
                
    }
}
