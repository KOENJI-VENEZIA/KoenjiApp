#!/usr/bin/swift

import Foundation

// Configuration
let projectDirectory = FileManager.default.currentDirectoryPath
let fileExtensions = ["swift"]

// Files that definitely need MainActor
var needsMainActor: [String] = []

// Files that should be checked
var checkFiles: [String] = []

// Process each file in the project directory recursively
func processFiles(in directoryPath: String) throws {
    let fileManager = FileManager.default
    let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
    
    for item in contents {
        let itemPath = (directoryPath as NSString).appendingPathComponent(item)
        var isDirectory: ObjCBool = false
        
        if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Recursively process subdirectories
                try processFiles(in: itemPath)
            } else {
                // Check file extension
                let fileExtension = (item as NSString).pathExtension.lowercased()
                if fileExtensions.contains(fileExtension) {
                    try processFile(at: itemPath)
                }
            }
        }
    }
}

// Process a single file
func processFile(at path: String) throws {
    // Read file content
    let content = try String(contentsOfFile: path, encoding: .utf8)
    
    // Check if the file contains AppLog calls
    if content.contains("AppLog.") {
        // Check if the file is already MainActor-isolated
        if content.contains("@MainActor") {
            // File is already properly isolated
            return
        }
        
        // Check for ObservableObject or UIViewController which likely need MainActor
        if content.contains("ObservableObject") || 
           content.contains("UIViewController") || 
           content.contains("UIView") {
            needsMainActor.append(path)
        } else {
            // Other files to check
            checkFiles.append(path)
        }
    }
}

// Main execution
do {
    print("Starting MainActor detection script...")
    try processFiles(in: projectDirectory)
    
    print("\n===== FILES THAT LIKELY NEED @MainActor =====")
    for file in needsMainActor.sorted() {
        print("- \(file)")
    }
    
    print("\n===== FILES TO CHECK FOR TASK { @MainActor in ... } =====")
    for file in checkFiles.sorted() {
        print("- \(file)")
    }
    
    print("\nIMPORTANT GUIDELINES:")
    print("1. Add @MainActor to view models and UI-related classes")
    print("2. For non-MainActor classes calling AppLog, use Task { @MainActor in ... }")
    print("3. For sync functions that can't be made async, create a helper method:")
    print("   private func logMessage(_ message: String) {")
    print("       Task { @MainActor in")
    print("           AppLog.debug(message)")
    print("       }")
    print("   }")
} catch {
    print("Error: \(error)")
} 