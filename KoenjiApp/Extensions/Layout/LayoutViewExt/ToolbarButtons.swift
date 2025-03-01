//
//  ToolbarButtons.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//

import SwiftUI

extension LayoutView {
    
    
    var dateBackward: some View {
        VStack {
            Text("-1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
    
                navigateToPreviousDate()
    
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    var dateForward: some View {
        VStack {
            Text("+1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToNextDate()
    
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }
    
    }
    
    var timeForward: some View {
    
        VStack {
            Text("+15 min.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToNextTime()
    
            }) {
                Image(systemName: "15.arrow.trianglehead.clockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    var timeBackward: some View {
    
        VStack {
            Text("-15 min.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToPreviousTime()
    
            }) {
                Image(systemName: "15.arrow.trianglehead.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    var lunchButton: some View {
    
        VStack {
            Text("Pranzo")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                unitView.isManuallyOverridden = true
                let lunchTime = "12:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: lunchTime)
                else {
                    LayoutView.logger.error("Failed to combine date and time for lunch button")
                    return
                }
                LayoutView.logger.debug("Setting lunch time: \(combinedTime)")
                withAnimation {
                    appState.selectedCategory = .lunch
                    appState.selectedDate = combinedTime
                }
            }) {
                Image(systemName: "sun.max.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    var dinnerButton: some View {
    
        VStack {
            Text("Cena")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                unitView.isManuallyOverridden = true
                let dinnerTime = "18:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: dinnerTime)
                else { return }
                withAnimation {
                    appState.selectedCategory = .dinner
                    appState.selectedDate = combinedTime
                }
            }) {
                Image(systemName: "moon.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    var resetTime: some View {
    
        VStack {
            Text("Adesso")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            // Reset to Default or System Time
            Button(action: {
                withAnimation {
                    let currentSystemTime = Date()
                    appState.selectedDate = DateHelper.combine(
                        date: appState.selectedDate, time: currentSystemTime)
                    LayoutView.logger.debug("Reset time to current system time: \(appState.selectedDate)")
                    unitView.isManuallyOverridden = false
                }
    
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .opacity(
            DateHelper.compareTimes(
                firstTime: appState.selectedDate, secondTime: timerManager.currentDate, interval: 60
            )
                ? 0 : 1
        )
        .animation(.easeInOut, value: appState.selectedDate)
    }
    
    @ViewBuilder
    func datePicker(selectedDate: Date) -> some View {
        VStack {
            Text("Data")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                unitView.showingDatePicker = true
            }) {
                Image(systemName: "calendar.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .popover(isPresented: $unitView.showingDatePicker) {
            DatePickerView()
                .environmentObject(appState)
                .frame(width: 300, height: 350)  // Adjust as needed
    
        }
    
    }
    
    var resetDate: some View {
        VStack {
            Text("Oggi")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                )
                .opacity(
                    Calendar.current.isDate(appState.selectedDate, inSameDayAs: unitView.systemTime) ? 0 : 1
                )
                .animation(.easeInOut, value: appState.selectedDate)
    
            Button(action: {
                withAnimation {
                    let today = Calendar.current.startOfDay(for: unitView.systemTime)  // Get today's date with no time component
                    guard let currentTimeOnly = DateHelper.extractTime(time: appState.selectedDate)
                    else {
                        return
                    }  // Extract time components
                    appState.selectedDate =
                        DateHelper.combinedInputTime(time: currentTimeOnly, date: today) ?? Date()
                    updateDatesAroundSelectedDate(appState.selectedDate)
                    unitView.isManuallyOverridden = false
                }
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .opacity(Calendar.current.isDate(appState.selectedDate, inSameDayAs: unitView.systemTime) ? 0 : 1)
        .animation(.easeInOut, value: appState.selectedDate)
    }
    
}

