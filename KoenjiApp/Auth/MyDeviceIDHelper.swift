//
//  MyDeviceIDHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/2/25.
//
//import KeychainAccess
//
//class MyDeviceIDHelper {
//    private static let key = "com.yourcompany.yourapp.deviceID"
//    
//    static func getPersistentDeviceID() -> String {
//        if let storedID = try? keychain.get("kishikawakatsumi") {
//            return storedID
//        } else {
//            let newID = UUID().uuidString
//            KeychainHelper.standard.save(newID, key: key)
//            return newID
//        }
//    }
//}
