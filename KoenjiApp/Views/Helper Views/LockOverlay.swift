//
//  LockOverlay.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 29/1/25.
//

import SwiftUI

struct LockOverlay: View {
    @Environment(\.colorScheme) var colorScheme
    var isLayoutLocked: Bool
    
    var body: some View {

        ZStack {
            
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .shadow(radius: 2.0)
                .frame(width: 200, height: 30)
            
            HStack(spacing: 0) {
                Image(systemName: isLayoutLocked ? "lock.trianglebadge.exclamationmark.fill" : "lock.open.trianglebadge.exclamationmark.fill")
                    .foregroundStyle(isLayoutLocked ? .red : Color.accentColor)
                Text(isLayoutLocked ? "Tavoli bloccati!" : "Tavoli sbloccati!")
                    .padding()
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
        }
    }


}

//#Preview {
//    LockOverlay()
//}
