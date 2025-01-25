//
//  BottomSheetControls.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//
import SwiftUI

struct BottomSheetControls: View {
    @Binding var dates: [Date]
    @Binding var selectedIndex: Int
    @Binding var selectedCategory: Reservation.ReservationCategory?
    @Binding var currentTime: Date
    @Binding var systemTime: Date
    @Binding var isManuallyOverridden: Bool
    @Binding var sidebarColor: Color
    let updateDatesAroundSelectedDate: (Date) -> Void // Closure for the method


    var onSidebarColorChange: ((Color) -> Void)?

    var body: some View {
        ZStack {
            sidebarColor
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                Text("Controls")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                    .padding(.horizontal)
                
                Divider()
                
                datePicker
                
                Divider()
                
                categoryPicker
                
                Divider()
                
                timePicker
                    .padding(.bottom)
                
                Spacer()
            }
            
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        
    }

    // MARK: - Date Picker
    private var datePicker: some View {
        VStack(alignment: .leading) {
            Text("Seleziona Giorno")
                .font(.caption)
            HStack(alignment: .center, spacing: 8) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { dates[safe: selectedIndex] ?? Date() },
                        set: { newDate in
                            
                            updateDatesAroundSelectedDate(newDate)
                        }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .frame(height: 44)
                
                // Reset to Default or System Time
                Button("Torna a oggi") {
                    withAnimation {
                        let today = Calendar.current.startOfDay(for: systemTime) // Get today's date with no time component
                        print("Today: \(today)")
                        guard let currentTimeOnly = DateHelper.extractTime(time: currentTime) else { return } // Extract time components
                        currentTime = DateHelper.combinedInputTime(time: currentTimeOnly, date: today) ?? Date()
                        updateDatesAroundSelectedDate(currentTime)
                        print("New currentTime: \(currentTime)")
                        isManuallyOverridden = false
                    }
                }
                .font(.caption)
                .opacity(Calendar.current.isDate(currentTime, inSameDayAs: systemTime) ? 0 : 1)
                .animation(.easeInOut, value: currentTime)
            }
        }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        VStack(alignment: .leading) {
            Text("Categoria")
                .font(.caption)
            Picker("Categoria", selection: $selectedCategory) {
                Text("Pranzo").tag(Reservation.ReservationCategory?.some(.lunch))
                Text("Cena").tag(Reservation.ReservationCategory?.some(.dinner))
            }
            .pickerStyle(.segmented)
            .frame(width: 200, height: 44)
            .onChange(of: selectedCategory) { oldCategory, newCategory in
                if let newCategory = newCategory {
                    onSidebarColorChange?(newCategory.sidebarColor)
                }
            }
        }
    }

    // MARK: - Time Picker
    private var timePicker: some View {
        VStack(alignment: .leading) {
            Text("Orario")
                .font(.caption)
            HStack(alignment: .center, spacing: 8) {
                // Time Picker
                DatePicker(
                    "Scegli orario",
                    selection: Binding(
                        get: { currentTime },
                        set: { newTime in
                            currentTime = DateHelper.combine(date: systemTime, time: newTime)
                            isManuallyOverridden = true // Mark as manually overridden
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                
                // Reset to Default or System Time
                Button("Torna all'ora corrente") {
                    withAnimation {
                        currentTime = systemTime // Reset to system time
                        isManuallyOverridden = false
                    }
                }
                .font(.caption)
                .opacity(DateHelper.compareTimes(firstTime: currentTime, secondTime: systemTime, interval: 60) ? 0 : 1)
                .animation(.easeInOut, value: currentTime)
            }
        }

        
    }
}
