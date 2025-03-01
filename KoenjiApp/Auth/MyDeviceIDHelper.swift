//
//  MyDeviceIDHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/2/25.
//


import Foundation
import os
import OSLog

class MyDeviceIDHelper {
    // MARK: - Private Properties
    let logger = Logger(subsystem: "com.koenjiapp", category: "MyDeviceIDHelper")
    
    private static let key = "com.yourcompany.yourapp.deviceID"
    
    static func getPersistentDeviceID() -> String {
        // Uncomment when implementing:
        /*
        if let storedID = try? keychain.get("kishikawakatsumi") {
            logger.debug("Retrieved existing device ID")
            return storedID
        } else {
            let newID = UUID().uuidString
            KeychainHelper.standard.save(newID, key: key)
            logger.info("Generated and saved new device ID")
            return newID
        }
        */
        return UUID().uuidString
    }
}
