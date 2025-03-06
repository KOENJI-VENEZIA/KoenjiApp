# KoenjiApp Documentation

This folder contains documentation tools, reports, and templates for the KoenjiApp project.

## Folder Structure

- **tools/**: Contains scripts and utilities for generating and analyzing documentation
  - `documentation_generator_v2.py`: Generates documentation suggestions for Swift files
  - `documentation_audit.py`: Analyzes documentation coverage across the codebase

- **reports/**: Contains generated documentation reports
  - Documentation audit reports
  - Coverage statistics

- **templates/**: Contains templates for documentation
  - Standard documentation templates for different code elements

## Usage

### Documentation Generator

The documentation generator can analyze Swift files and suggest documentation for classes, methods, and properties:

```bash
python3 Documentation/tools/documentation_generator_v2.py path/to/file.swift
```

### Documentation Audit

The documentation audit tool analyzes the codebase and generates a report on documentation coverage:

```bash
python3 Documentation/tools/documentation_audit.py [directory] --output Documentation/reports/audit_report.md
```

## Best Practices

1. **Meaningful Documentation**: Focus on explaining "why" rather than "what" the code does
2. **Keep Documentation Updated**: Update documentation when code changes
3. **Document Public APIs**: Prioritize documentation for public interfaces
4. **Use Standard Format**: Follow Swift documentation conventions with `///` comments
5. **Include Examples**: Where appropriate, include usage examples

## Documentation Format

For Swift files, use the following format:

```swift
/// Brief description of what this does
///
/// More detailed explanation if needed
///
/// - Parameters:
///   - paramName: Description of the parameter
/// - Returns: Description of the return value
/// - Throws: Description of potential errors
``` 