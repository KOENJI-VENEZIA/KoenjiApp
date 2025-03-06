# Documentation Tools Changelog

## 2023-07-10

### Fixed
- Fixed issue with duplicate class entries in audit reports when a class has multiple extensions
- Modified `documentation_generator_v2.py` to properly handle Swift extensions:
  - Separated class pattern to only match actual class declarations (not extensions)
  - Added a separate extension pattern to track extension names
  - Implemented a set to track processed class names to avoid duplicates
  - Added check to prevent counting extensions as separate undocumented classes

### Impact
- More accurate documentation coverage statistics
- Cleaner audit reports without duplicate entries
- Reduced confusion when identifying undocumented classes 