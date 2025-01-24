//
//  DatePicker.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var hasSelectedStartDate: Bool
    @Binding var hasSelectedEndDate: Bool
    
    init(selectedDate: Binding<Date>, hasSelectedStartDate: Binding<Bool> = Binding.constant(false), hasSelectedEndDate: Binding<Bool> = Binding.constant(false)) {
        self._selectedDate = selectedDate
        self._hasSelectedStartDate = hasSelectedStartDate
        self._hasSelectedEndDate = hasSelectedEndDate
    }
    
    var body: some View {
        
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                    
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .onChange(of: selectedDate) {
                    hasSelectedStartDate = true
                    hasSelectedEndDate = true
                }
                
    }
}
