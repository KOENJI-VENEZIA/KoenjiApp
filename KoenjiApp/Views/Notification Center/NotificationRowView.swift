//
//  NotificationRow.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 4/2/25.
//

import SwiftUI

struct NotificationRowView: View {
    let notification: AppNotification

    var onTap: () -> Void
    var onDelete: () -> Void
    var onAction: () -> Void
    
    var sentOn: Double {
        Date().timeIntervalSince(notification.date) / 60
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12.0)
                .fill(.regularMaterial)
                .frame(maxWidth: .infinity, maxHeight: 70)

            VStack(alignment: .leading) {
                
                HStack(spacing: 10) {
                    Image("KoenjiIcon")
                        .resizable()
                        .scaledToFit()
                        .drawingGroup()
                        .frame(maxWidth: 40, maxHeight: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    
                    
                    Text(notification.message)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .bold()
                    
                    Spacer()
                    
                    TagButtonView(notification: notification)
                        .padding(.trailing)
                    
                    Text(TimeHelpers.elapsedTimeString(date: notification.date, currentTime: Date()))
                        .font(.caption)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .padding()
    }
}

struct TagButtonView: View {
    let notification: AppNotification
    
    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(notification.reservation?.assignedColor ?? Color.sidebar_generic)
                .frame(height: 25)
            Text("#\(notification.type.localized)")
                .font(.caption)
                .bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: 100, maxHeight: 25)
    }
}

extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}

struct AppIcon: View {
    var body: some View {
        Bundle.main.iconFileName
            .flatMap { UIImage(named: $0) }
            .map { Image(uiImage: $0) }
    }
}
