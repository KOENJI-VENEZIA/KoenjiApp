//
//  DatePicker.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                    
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
    }
}
