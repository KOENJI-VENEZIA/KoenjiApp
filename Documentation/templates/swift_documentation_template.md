# Swift Documentation Templates

This file contains templates for documenting different Swift code elements.

## Class/Struct/Enum Documentation

```swift
/// A brief description of what this type does or represents.
///
/// A more detailed description that explains the purpose, responsibilities,
/// and any important details about this type. Include usage examples if helpful.
///
/// - Note: Include any important notes or caveats here.
/// - Warning: Include any warnings about potential issues here.
```

## Method Documentation

```swift
/// A brief description of what this method does.
///
/// A more detailed description that explains the purpose and behavior of this method.
/// Include any important details or edge cases that users should be aware of.
///
/// - Parameters:
///   - paramName1: Description of the first parameter
///   - paramName2: Description of the second parameter
/// - Returns: Description of the return value and what it represents
/// - Throws: Description of the errors that can be thrown and under what conditions
///
/// - Note: Any additional notes about usage
///
/// # Example
/// ```swift
/// let result = myMethod(param1: value1, param2: value2)
/// ```
```

## Property Documentation

```swift
/// A description of what this property represents and its purpose.
///
/// Include any important details about the property, such as:
/// - Default values
/// - Valid ranges or constraints
/// - Side effects of setting the property
/// - Whether it's thread-safe
```

## Protocol Documentation

```swift
/// A brief description of the protocol's purpose.
///
/// A more detailed description that explains what this protocol represents,
/// when it should be adopted, and any requirements for conforming types.
///
/// ## Requirements
///
/// Types conforming to this protocol must:
/// - Implement required methods and properties
/// - Handle specific behaviors
/// - Meet any performance expectations
```

## Extension Documentation

```swift
/// Extends the functionality of Type to provide additional capabilities.
///
/// Describe what new functionality this extension adds and why it's useful.
```

## Enum Case Documentation

```swift
/// An enumeration representing different states of a process.
enum ProcessState {
    /// The process is waiting to start.
    case waiting
    
    /// The process is currently running.
    /// - Note: This state indicates active processing is happening.
    case running
    
    /// The process has completed successfully.
    /// - Parameter result: The result produced by the process.
    case completed(result: Any)
    
    /// The process failed with an error.
    /// - Parameter error: The error that caused the failure.
    case failed(error: Error)
}
```

## Closure Parameter Documentation

```swift
/// Performs an operation with the provided completion handler.
///
/// - Parameters:
///   - input: The input value for the operation
///   - completion: A closure called when the operation completes
///     - Parameter success: Whether the operation was successful
///     - Parameter result: The result of the operation, if successful
///     - Parameter error: The error that occurred, if unsuccessful
func performOperation(
    input: String,
    completion: (_ success: Bool, _ result: String?, _ error: Error?) -> Void
)
```

## MARK Comments for Code Organization

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods

// MARK: - Protocol Conformance
// MARK: UITableViewDelegate

// MARK: - Helper Methods
``` 