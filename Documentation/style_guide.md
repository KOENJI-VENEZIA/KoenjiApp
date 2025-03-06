# KoenjiApp Documentation Style Guide

This style guide outlines the conventions and best practices for documenting code in the KoenjiApp project.

## General Principles

1. **Be Clear and Concise**: Write documentation that is easy to understand and to the point.
2. **Focus on Why, Not Just What**: Explain the reasoning behind code decisions, not just what the code does.
3. **Keep Documentation Updated**: Documentation should be treated as part of the code and updated when code changes.
4. **Document Public APIs Thoroughly**: Public interfaces should be well-documented as they are used by other developers.
5. **Use Consistent Formatting**: Follow the formatting conventions outlined in this guide.

## Swift Documentation Conventions

### Comment Style

Use `///` for documentation comments that should be picked up by documentation tools:

```swift
/// This is a documentation comment
```

Use `//` for implementation notes and TODOs that are not part of the public documentation:

```swift
// TODO: Refactor this method to improve performance
```

### Documentation Structure

Documentation should generally follow this structure:

1. A brief summary (one line if possible)
2. A more detailed description (if needed)
3. Parameter descriptions (for methods)
4. Return value description (for methods that return values)
5. Thrown errors (for methods that throw)
6. Notes, warnings, or examples (if applicable)

### Code Organization

Use `MARK:` comments to organize your code into logical sections:

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods

// MARK: - Protocol Conformance
```

## Documentation Priorities

Not all code needs the same level of documentation. Focus your efforts based on this priority:

1. **Public APIs**: Methods and properties that are used by other modules
2. **Complex Logic**: Code that implements complex business rules or algorithms
3. **Non-obvious Code**: Anything that might not be immediately clear to another developer
4. **Private Implementation Details**: Document when they involve complex logic or non-obvious decisions

## Language and Tone

1. **Use Present Tense**: Write "Returns the count" instead of "Will return the count"
2. **Be Direct**: Write "Calculates the total" instead of "This method calculates the total"
3. **Use Active Voice**: Write "Saves the file" instead of "The file is saved"
4. **Be Consistent**: Use the same terminology throughout the documentation

## Examples

### Class/Struct Documentation

```swift
/// Manages reservation assignments to tables in the restaurant.
///
/// The TableAssignmentService is responsible for determining if tables are available
/// for a given reservation time period and assigning appropriate tables based on
/// party size and existing reservations.
```

### Method Documentation

```swift
/// Checks if a table is occupied for a given time period.
///
/// This method determines if a table is already assigned to an active reservation
/// during the specified time period. It excludes reservations with statuses like
/// canceled, no-show, or deleted, as well as waiting list reservations.
///
/// - Parameters:
///   - tableID: The ID of the table to check
///   - reservationDate: The date of the reservation
///   - startTime: The start time of the period to check
///   - endTime: The end time of the period to check
///   - excludeReservationID: Optional ID of a reservation to exclude from the check
/// - Returns: `true` if the table is occupied during the specified period, `false` otherwise
```

### Property Documentation

```swift
/// The collection of tables currently available in the restaurant.
///
/// This property is updated whenever the table layout changes and is used
/// for table assignment and availability calculations.
```

## Reviewing Documentation

When reviewing code, consider these documentation aspects:

1. Is the documentation clear and understandable?
2. Does it explain the "why" behind complex logic?
3. Are all parameters, return values, and thrown errors documented?
4. Is the documentation consistent with the actual code behavior?
5. Are there any outdated or incorrect statements?

## Tools

Use the documentation tools in the `Documentation/tools` directory to help maintain documentation quality:

- `documentation_generator_v2.py`: Generates documentation suggestions
- `documentation_audit.py`: Analyzes documentation coverage 