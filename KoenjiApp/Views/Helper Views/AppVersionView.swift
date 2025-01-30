//
//  AppVersionView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 24/1/25.
//


import SwiftUI

struct AppVersionView: View {
    // Fetch app version and build number
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("App Version: \(appVersion)")
                .font(.headline)
            #if DEBUG
            Text("Build: \(buildNumber) (debug ver.)")
                .font(.subheadline)
            #else
            Text("Build: \(buildNumber) (release)")
                .font(.subheadline)
            #endif
            Text("Matteo Nassini\n© All Rights Reserved")
                .font(.subheadline)
        }
        .padding()
    }
}
