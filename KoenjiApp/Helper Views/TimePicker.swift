//  TimePicker.swift
//  KoenjiApp

import SwiftUI

struct TimePicker: View {
    @Binding var selectedTime: Date
    let minimumTime: Date
    let maximumTime: Date
    let onTimeChange: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Seleziona Orario")
                .font(.caption)
                .foregroundColor(.gray)

            DatePicker(
                "",
                selection: $selectedTime,
                in: minimumTime...maximumTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .onChange(of: selectedTime) {
                onTimeChange?()
            }
            .frame(height: 44)
        }
    }
}

// MARK: - Usage Example
struct TimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TimePicker(
            selectedTime: .constant(Date()),
            minimumTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            maximumTime: Calendar.current.date(bySettingHour: 21, minute: 45, second: 0, of: Date())!,
            onTimeChange: {}
        )
        .padding()
    }
}
