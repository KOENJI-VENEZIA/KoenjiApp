import Foundation
import Logging
import Firebase
import FirebaseStorage
import OSLog

/// A global logging utility that provides easy access to logging functions
/// without requiring explicit initialization in every file
@MainActor
enum AppLog {
    
    /// Internal logger storage
    private static var loggers: [String: Logging.Logger] = [:]
    
    /// Whether Firebase logging is enabled
    static var firebaseLoggingEnabled = false
    
    /// Firestore database reference
    static var db: Firestore? = nil
    
    /// Initialize the logging system (call once at app startup)
    static func initialize() {
        // Setup Swift Log bootstrap
        LoggingSystem.bootstrap { label in
            let osLogger = OSLogHandler(label: label)
            let firebaseLogger = FirebaseLogHandler(label: label)
            return MultiplexLogHandler([osLogger, firebaseLogger])
        }
        
        // Setup Firebase if available
        db = Firestore.firestore()
        
        print("[AppLog] Logging system initialized")
    }
    
    /// Enable or disable Firebase logging
    static func setFirebaseLogging(enabled: Bool) {
        firebaseLoggingEnabled = enabled
        print("[AppLog] Firebase logging: \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get a logger for a specific category
    static func forCategory(_ category: String) -> Logging.Logger {
        if let logger = loggers[category] {
            return logger
        }
        
        let logger = Logging.Logger(label: category)
        loggers[category] = logger
        return logger
    }
    
    /// Log a debug message
    static func debug(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: UInt = #line) {
        forCategory(category).debug("\(message)", file: file, function: function, line: line)
    }
    
    /// Log an info message
    static func info(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: UInt = #line) {
        forCategory(category).info("\(message)", file: file, function: function, line: line)
    }
    
    /// Log a warning message
    static func warning(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: UInt = #line) {
        forCategory(category).warning("\(message)", file: file, function: function, line: line)
    }
    
    /// Log an error message
    static func error(_ message: String, category: String = "App", file: String = #file, function: String = #function, line: UInt = #line) {
        forCategory(category).error("\(message)", file: file, function: function, line: line)
    }
}

// MARK: - Log Handlers

/// A log handler that logs to OSLog
struct OSLogHandler: LogHandler {
    let label: String
    let osLogger: OSLog
    
    init(label: String) {
        self.label = label
        self.osLogger = OSLog(subsystem: "com.koenjiapp", category: label)
    }
    
    // Standard LogHandler properties
    var logLevel: Logging.Logger.Level = .info
    var metadata: Logging.Logger.Metadata = [:]
    
    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
    
    func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let combinedMetadata = mergeMetadata(self.metadata, metadata)
        let metadataString = combinedMetadata.isEmpty ? "" : " \(combinedMetadata)"
        
        let osLogType: OSLogType
        switch level {
        case .trace, .debug:
            osLogType = .debug
        case .info, .notice:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .critical:
            osLogType = .fault
        }
        
        // Log to OSLog
        os_log("%{public}@%{public}@", log: osLogger, type: osLogType, "\(message)", metadataString)
    }
    
    private func mergeMetadata(_ lhs: Logging.Logger.Metadata, _ rhs: Logging.Logger.Metadata?) -> Logging.Logger.Metadata {
        var result: Logging.Logger.Metadata = lhs
        if let rhs = rhs {
            for (key, value) in rhs {
                result[key] = value
            }
        }
        return result
    }
}

/// A log handler that logs to Firebase
struct FirebaseLogHandler: LogHandler {
    let label: String
    
    init(label: String) {
        self.label = label
    }
    
    // Standard LogHandler properties
    var logLevel: Logging.Logger.Level = .info
    var metadata: Logging.Logger.Metadata = [:]
    
    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
    
    // This is the protocol requirement (nonisolated)
    func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        // Dispatch to main actor for actual implementation
        Task { @MainActor in
            logOnMainActor(level: level, message: message, metadata: metadata, source: source, file: file, function: function, line: line)
        }
    }
    
    // Actual implementation on MainActor
    @MainActor private func logOnMainActor(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        // Skip if not enabled
        guard AppLog.firebaseLoggingEnabled, let db = AppLog.db else { return }
        
        // Only log at warning level or higher to Firebase to reduce noise
        guard level >= Logging.Logger.Level.warning else { return }
        
        let combinedMetadata = mergeMetadata(self.metadata, metadata)
        
        // Prepare log data
        let logData: [String: Any] = [
            "message": "\(message)",
            "level": level.rawValue,
            "label": label,
            "source": source,
            "file": URL(fileURLWithPath: file).lastPathComponent,
            "function": function,
            "line": line,
            "metadata": combinedMetadata.mapValues { "\($0)" },
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Use synchronous Firebase API with completion handler
        let logsCollection = db.collection("application_logs")
        logsCollection.addDocument(data: logData) { error in
            if let error = error {
                // If logging to Firebase fails, log to local console instead
                // Note: We don't use regular logging here to avoid potential infinite recursion
                print("Failed to log to Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    private func mergeMetadata(_ lhs: Logging.Logger.Metadata, _ rhs: Logging.Logger.Metadata?) -> Logging.Logger.Metadata {
        var result: Logging.Logger.Metadata = lhs
        if let rhs = rhs {
            for (key, value) in rhs {
                result[key] = value
            }
        }
        return result
    }
} 