//
//  PeoplePickerView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct PeoplePickerView: View {
    @Binding var filterPeople: Int
    @Binding var hasSelectedPeople: Bool
    
    var body: some View {
        
        Picker("Seleziona persone", selection: $filterPeople) {
            ForEach(1...14, id: \.self) { number in
                Text("\(number)").tag(number)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .labelsHidden()
        .onChange(of: filterPeople) {
            hasSelectedPeople = true
        }
                
    }
}
