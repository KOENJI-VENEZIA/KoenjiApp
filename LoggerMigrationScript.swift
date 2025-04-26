#!/usr/bin/swift

import Foundation

// Configuration
let projectDirectory = FileManager.default.currentDirectoryPath
let fileExtensions = ["swift"]
let dryRun = false // Set to false to actually modify files

// Regex patterns
let loggerPatterns = [
    // AppLog.debug("message")
    #"([\s\(])logger\.(debug|info|notice|warning|error)\(([^)]+)\)"#,
    
    // AppLog.debug("message") or AppLog.debug("message")
    #"([\s\(])self\.logger\??\.(debug|info|notice|warning|error)\(([^)]+)\)"#,
    
    // AppLog.debug("message")
    #"([\s\(])Self\.logger\.(debug|info|notice|warning|error)\(([^)]+)\)"#
]

// Keep track of processed files
var processedFileCount = 0
var modifiedFileCount = 0

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
    processedFileCount += 1
    
    // Read file content
    let content = try String(contentsOfFile: path, encoding: .utf8)
    var modifiedContent = content
    var fileModified = false
    
    // Apply replacements using regex
    for pattern in loggerPatterns {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            continue
        }
        
        let matches = regex.matches(in: modifiedContent, options: [], range: NSRange(modifiedContent.startIndex..., in: modifiedContent))
        
        // Apply replacements in reverse order to avoid offset issues
        for match in matches.reversed() {
            guard match.numberOfRanges >= 4 else { continue }
            
            let prefixRange = match.range(at: 1)
            let levelRange = match.range(at: 2)
            let messageRange = match.range(at: 3)
            
            guard 
                let prefixRangeSwift = Range(prefixRange, in: modifiedContent),
                let levelRangeSwift = Range(levelRange, in: modifiedContent),
                let messageRangeSwift = Range(messageRange, in: modifiedContent)
            else { continue }
            
            let prefix = String(modifiedContent[prefixRangeSwift])
            var level = String(modifiedContent[levelRangeSwift])
            let message = String(modifiedContent[messageRangeSwift])
            
            // Convert 'notice' to 'info'
            if level == "notice" {
                level = "info"
            }
            
            // Create the replacement
            let replacement = "\(prefix)AppLog.\(level)(\(message))"
            
            // Apply the replacement
            let fullMatchRange = Range(match.range, in: modifiedContent)!
            modifiedContent.replaceSubrange(fullMatchRange, with: replacement)
            fileModified = true
        }
    }
    
    // Save changes if the file was modified
    if fileModified && !dryRun {
        try modifiedContent.write(toFile: path, atomically: true, encoding: .utf8)
        modifiedFileCount += 1
        print("Modified: \(path)")
    } else if fileModified {
        print("Would modify: \(path)")
    }
}

// Main execution
do {
    print("Starting logger migration script...")
    try processFiles(in: projectDirectory)
    print("Completed processing \(processedFileCount) Swift files.")
    if dryRun {
        print("Dry run mode: Would have modified \(modifiedFileCount) files.")
    } else {
        print("Modified \(modifiedFileCount) files.")
    }
    print("\nIMPORTANT: This script doesn't handle actor isolation. You'll need to manually review files and:")
    print("1. Add @MainActor to appropriate classes")
    print("2. Add 'Task { @MainActor in ... }' where needed for async contexts")
    print("\nFiles to check for actor isolation issues (grep for 'AppLog.'):")
    print("grep -r 'AppLog\\.' --include='*.swift' \(projectDirectory)")
} catch {
    print("Error: \(error)")
} 