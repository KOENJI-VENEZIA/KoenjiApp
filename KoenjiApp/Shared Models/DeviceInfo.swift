//
//  DeviceInfo.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import UIKit
import Foundation
import OSLog

/// A utility class for getting device information
@MainActor
class DeviceInfo {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = DeviceInfo()
    
    /// Logger for tracking device operations
    private let logger = Logger(subsystem: "com.koenjiapp", category: "DeviceInfo")
    
    /// Cached device name
    private var cachedDeviceName: String?
    
    /// Cached device identifier
    private var cachedDeviceIdentifier: String?
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Initialize cache
        initializeCache()
    }
    
    // MARK: - Public Methods
    
    /// Returns the current device name with model information
    ///
    /// This method returns a user-friendly device name that includes both the device model
    /// (e.g., "iPhone", "iPad") and the specific model (e.g., "iPhone 13", "iPad Pro").
    ///
    /// - Returns: A string containing the device name and model
    func getDeviceName() -> String {
        if let cachedName = cachedDeviceName {
            return cachedName
        }
        
        // If cache is empty, initialize it
        initializeCache()
        return cachedDeviceName ?? "Unknown Device"
    }
    
    /// Returns a stable device identifier that persists across app launches
    ///
    /// This method returns a unique identifier for the device that remains consistent
    /// across app launches. It uses the device's identifierForVendor if available,
    /// and falls back to a stored UUID if necessary.
    ///
    /// - Returns: A string containing the stable device identifier
    func getStableDeviceIdentifier() -> String {
        if let cachedID = cachedDeviceIdentifier {
            return cachedID
        }
        
        // If cache is empty, initialize it
        initializeCache()
        return cachedDeviceIdentifier ?? UUID().uuidString
    }
    
    // MARK: - Private Methods
    
    /// Initializes the cache with device information
    private func initializeCache() {
        // Get device model (thread-safe)
        let deviceModel = Self.getDeviceModel()
        
        // Get device name (main thread only)
        let rawDeviceName = UIDevice.current.name
        
        // Create the full device name
        if deviceModel != "Unknown" {
            cachedDeviceName = "\(deviceModel) (\(rawDeviceName))"
        } else {
            cachedDeviceName = rawDeviceName
        }
        
        AppLog.debug("Device name initialized: \(self.cachedDeviceName ?? "Unknown")")
        
        // Get device identifier
        let deviceIdentifierKey = "com.koenjiapp.stableDeviceIdentifier"
        
        // Check if we already have a stored identifier
        if let storedIdentifier = UserDefaults.standard.string(forKey: deviceIdentifierKey),
           !storedIdentifier.isEmpty {
            cachedDeviceIdentifier = storedIdentifier
            AppLog.debug("Using stored device identifier")
        } else {
            // Get a new identifier
            if let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString {
                cachedDeviceIdentifier = vendorIdentifier
                AppLog.debug("Using vendor identifier")
            } else {
                cachedDeviceIdentifier = UUID().uuidString
                AppLog.debug("Using generated UUID")
            }
            
            // Store it for future use
            UserDefaults.standard.set(cachedDeviceIdentifier, forKey: deviceIdentifierKey)
        }
    }
    
    /// Returns the device model
    ///
    /// This method returns the device model (e.g., "iPhone 13", "iPad Pro").
    ///
    /// - Returns: A string containing the device model
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return mapToDeviceModel(identifier: identifier)
    }
    
    /// Maps a device identifier to a user-friendly device model name
    ///
    /// This method maps a device identifier (e.g., "iPhone14,2") to a user-friendly
    /// device model name (e.g., "iPhone 13 Pro").
    ///
    /// - Parameter identifier: The device identifier
    /// - Returns: A user-friendly device model name
    private static func mapToDeviceModel(identifier: String) -> String {
        // Simulator
        if identifier == "i386" || identifier == "x86_64" || identifier == "arm64" {
            return "iPhone Simulator"
        }
        
        // iPhone
        if identifier.starts(with: "iPhone") {
            switch identifier {
            case "iPhone1,1": return "iPhone"
            case "iPhone1,2": return "iPhone 3G"
            case "iPhone2,1": return "iPhone 3GS"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
            case "iPhone4,1": return "iPhone 4S"
            case "iPhone5,1", "iPhone5,2": return "iPhone 5"
            case "iPhone5,3", "iPhone5,4": return "iPhone 5C"
            case "iPhone6,1", "iPhone6,2": return "iPhone 5S"
            case "iPhone7,1": return "iPhone 6 Plus"
            case "iPhone7,2": return "iPhone 6"
            case "iPhone8,1": return "iPhone 6s"
            case "iPhone8,2": return "iPhone 6s Plus"
            case "iPhone8,4": return "iPhone SE"
            case "iPhone9,1", "iPhone9,3": return "iPhone 7"
            case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4": return "iPhone 8"
            case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6": return "iPhone X"
            case "iPhone11,2": return "iPhone XS"
            case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
            case "iPhone11,8": return "iPhone XR"
            case "iPhone12,1": return "iPhone 11"
            case "iPhone12,3": return "iPhone 11 Pro"
            case "iPhone12,5": return "iPhone 11 Pro Max"
            case "iPhone12,8": return "iPhone SE (2nd Gen)"
            case "iPhone13,1": return "iPhone 12 Mini"
            case "iPhone13,2": return "iPhone 12"
            case "iPhone13,3": return "iPhone 12 Pro"
            case "iPhone13,4": return "iPhone 12 Pro Max"
            case "iPhone14,2": return "iPhone 13 Pro"
            case "iPhone14,3": return "iPhone 13 Pro Max"
            case "iPhone14,4": return "iPhone 13 Mini"
            case "iPhone14,5": return "iPhone 13"
            case "iPhone14,6": return "iPhone SE (3rd Gen)"
            case "iPhone14,7": return "iPhone 14"
            case "iPhone14,8": return "iPhone 14 Plus"
            case "iPhone15,2": return "iPhone 14 Pro"
            case "iPhone15,3": return "iPhone 14 Pro Max"
            case "iPhone15,4": return "iPhone 15"
            case "iPhone15,5": return "iPhone 15 Plus"
            case "iPhone16,1": return "iPhone 15 Pro"
            case "iPhone16,2": return "iPhone 15 Pro Max"
            case "iPhone17,1": return "iPhone 16 Pro"
            case "iPhone17,2": return "iPhone 16 Pro Max"
            case "iPhone17,3": return "iPhone 16"
            case "iPhone17,4": return "iPhone 16 Plus"
            default: return "iPhone"
            }
        }
        
        // iPod
        if identifier.starts(with: "iPod") {
            switch identifier {
            case "iPod1,1": return "iPod Touch (1st Gen)"
            case "iPod2,1": return "iPod Touch (2nd Gen)"
            case "iPod3,1": return "iPod Touch (3rd Gen)"
            case "iPod4,1": return "iPod Touch (4th Gen)"
            case "iPod5,1": return "iPod Touch (5th Gen)"
            case "iPod7,1": return "iPod Touch (6th Gen)"
            case "iPod9,1": return "iPod Touch (7th Gen)"
            default: return "iPod Touch"
            }
        }
        
        // iPad
        if identifier.starts(with: "iPad") {
            switch identifier {
            case "iPad1,1", "iPad1,2": return "iPad"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
            case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad Mini"
            case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad (3rd Gen)"
            case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad (4th Gen)"
            case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
            case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad Mini 3"
            case "iPad5,1", "iPad5,2": return "iPad Mini 4"
            case "iPad5,3", "iPad5,4": return "iPad Air 2"
            case "iPad6,3", "iPad6,4": return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch)"
            case "iPad6,11", "iPad6,12": return "iPad (5th Gen)"
            case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch) (2nd Gen)"
            case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
            case "iPad7,5", "iPad7,6": return "iPad (6th Gen)"
            case "iPad7,11", "iPad7,12": return "iPad (7th Gen)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch) (3rd Gen)"
            case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch) (2nd Gen)"
            case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch) (4th Gen)"
            case "iPad11,1", "iPad11,2": return "iPad Mini (5th Gen)"
            case "iPad11,3", "iPad11,4": return "iPad Air (3rd Gen)"
            case "iPad11,6", "iPad11,7": return "iPad (8th Gen)"
            case "iPad12,1", "iPad12,2": return "iPad (9th Gen)"
            case "iPad13,1", "iPad13,2": return "iPad Air (4th Gen)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (11-inch) (3rd Gen)"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (12.9-inch) (5th Gen)"
            case "iPad13,16", "iPad13,17": return "iPad Air (5th Gen)"
            case "iPad13,18", "iPad13,19": return "iPad (10th Gen)"
            case "iPad14,1", "iPad14,2": return "iPad Mini (6th Gen)"
            case "iPad14,3", "iPad14,4": return "iPad Pro (11-inch) (4th Gen)"
            case "iPad14,5", "iPad14,6": return "iPad Pro (12.9-inch) (6th Gen)"
            case "iPad14,8", "iPad14,9": return "iPad Air (6th Gen)"
            case "iPad14,10", "iPad14,11": return "iPad Air (7th Gen)"
            case "iPad16,1", "iPad16,2": return "iPad Mini (7th Gen)"
            case "iPad16,3", "iPad16,4": return "iPad Pro (11-inch) (5th Gen)"
            case "iPad16,5", "iPad16,6": return "iPad Pro (12.9-inch) (7th Gen)"
            default: return "iPad"
            }
        }
        
        // Mac
        if identifier.starts(with: "Mac") {
            return "Mac"
        }
        
        return "Unknown"
    }
} 
