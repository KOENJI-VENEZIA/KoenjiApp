#!/usr/bin/env python3
import os
import re
import sys
import json
import argparse
from pathlib import Path

class DocumentationGenerator:
    def __init__(self):
        # Regex patterns for Swift code
        self.class_pattern = re.compile(r'(?:public |private |internal |fileprivate |open )*(?:final )?(?:class|struct|enum|protocol|extension) +(\w+)')
        self.method_pattern = re.compile(r'(?:public |private |internal |fileprivate |open )*(?:static |class |override )*func +(\w+)')
        self.property_pattern = re.compile(r'(?:public |private |internal |fileprivate |open )*(?:static |class )*(?:let|var) +(\w+)')
        
        # Pattern to detect existing documentation
        self.doc_pattern = re.compile(r'///.*')
        
        # Results storage
        self.suggestions = {
            'class': [],
            'method': [],
            'property': []
        }
        
        # Statistics for analysis mode
        self.stats = {
            'total_items': 0,
            'documented_items': 0,
            'coverage_percentage': 0,
            'missing_documentation': {
                'classes': [],
                'methods': [],
                'properties': []
            }
        }
    
    def extract_context(self, content, match_start, context_lines=3):
        """Extract context around a code declaration."""
        lines = content.split('\n')
        
        # Find the line number for the match
        line_start = content[:match_start].count('\n')
        
        # Extract context lines before and after
        start_line = max(0, line_start - context_lines)
        end_line = min(len(lines), line_start + context_lines + 1)
        
        return '\n'.join(lines[start_line:end_line])
    
    def has_documentation(self, content, match_start):
        """Check if there's documentation before the match."""
        # Look at the 5 lines before the match
        prev_newline = content.rfind('\n', 0, match_start)
        if prev_newline == -1:
            prev_newline = 0
        else:
            prev_newline = content.rfind('\n', 0, prev_newline)
            if prev_newline == -1:
                prev_newline = 0
        
        prev_content = content[prev_newline:match_start]
        
        # Check for documentation comments
        return bool(self.doc_pattern.search(prev_content))
    
    def analyze_file(self, file_path, analyze_only=False):
        """Analyze a Swift file and generate documentation suggestions."""
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Reset statistics and suggestions
        self.stats = {
            'total_items': 0,
            'documented_items': 0,
            'coverage_percentage': 0,
            'missing_documentation': {
                'classes': [],
                'methods': [],
                'properties': []
            }
        }
        
        self.suggestions = {
            'class': [],
            'method': [],
            'property': []
        }
        
        # Find classes, structs, enums, protocols, and extensions
        for match in self.class_pattern.finditer(content):
            class_name = match.group(1)
            self.stats['total_items'] += 1
            
            if self.has_documentation(content, match.start()):
                self.stats['documented_items'] += 1
            else:
                context = self.extract_context(content, match.start())
                if not analyze_only:
                    self.suggestions['class'].append({
                        'name': class_name,
                        'line': content[:match.start()].count('\n') + 1,
                        'context': context
                    })
                self.stats['missing_documentation']['classes'].append(class_name)
        
        # Find methods
        for match in self.method_pattern.finditer(content):
            method_name = match.group(1)
            self.stats['total_items'] += 1
            
            if self.has_documentation(content, match.start()):
                self.stats['documented_items'] += 1
            else:
                context = self.extract_context(content, match.start())
                if not analyze_only:
                    self.suggestions['method'].append({
                        'name': method_name,
                        'line': content[:match.start()].count('\n') + 1,
                        'context': context
                    })
                self.stats['missing_documentation']['methods'].append(method_name)
        
        # Find properties
        for match in self.property_pattern.finditer(content):
            property_name = match.group(1)
            self.stats['total_items'] += 1
            
            if self.has_documentation(content, match.start()):
                self.stats['documented_items'] += 1
            else:
                context = self.extract_context(content, match.start())
                if not analyze_only:
                    self.suggestions['property'].append({
                        'name': property_name,
                        'line': content[:match.start()].count('\n') + 1,
                        'context': context
                    })
                self.stats['missing_documentation']['properties'].append(property_name)
        
        # Calculate coverage percentage
        if self.stats['total_items'] > 0:
            self.stats['coverage_percentage'] = (self.stats['documented_items'] / self.stats['total_items']) * 100
        
        return self.suggestions, self.stats
    
    def generate_documentation_report(self, file_path):
        """Generate a documentation report for a Swift file."""
        suggestions, _ = self.analyze_file(file_path)
        
        file_name = os.path.basename(file_path)
        report = [f"# Documentation Suggestions for {file_name}\n"]
        report.append(f"File: {file_path}")
        
        total_suggestions = sum(len(suggestions[key]) for key in suggestions)
        report.append(f"Total suggestions: {total_suggestions}\n")
        
        # Add class documentation suggestions
        if suggestions['class']:
            report.append(f"## Class Documentation ({len(suggestions['class'])})\n")
            for i, suggestion in enumerate(suggestions['class']):
                report.append(f"### {suggestion['name']} (Line {suggestion['line']})\n")
                report.append("**Context:**\n")
                report.append(f"```swift\n{suggestion['context']}\n```\n")
                report.append("**Suggested Documentation:**\n")
                report.append(f"```swift\n/// {suggestion['name']} {self._get_type_name(suggestion['name'])}.\n///\n/// [Add a description of what this {self._get_type_name(suggestion['name'])} does and its responsibilities]\n```\n")
        
        # Add method documentation suggestions
        if suggestions['method']:
            report.append(f"## Method Documentation ({len(suggestions['method'])})\n")
            for i, suggestion in enumerate(suggestions['method']):
                report.append(f"### {suggestion['name']} (Line {suggestion['line']})\n")
                report.append("**Context:**\n")
                report.append(f"```swift\n{suggestion['context']}\n```\n")
                report.append("**Suggested Documentation:**\n")
                report.append(f"```swift\n/// [Add a description of what the {suggestion['name']} method does]\n///\n/// - Parameters:\n///   - [parameter]: [Description of parameter]\n/// - Returns: [Description of the return value]\n```\n")
        
        # Add property documentation suggestions
        if suggestions['property']:
            report.append(f"## Property Documentation ({len(suggestions['property'])})\n")
            for i, suggestion in enumerate(suggestions['property']):
                report.append(f"### {suggestion['name']} (Line {suggestion['line']})\n")
                report.append("**Context:**\n")
                report.append(f"```swift\n{suggestion['context']}\n```\n")
                report.append("**Suggested Documentation:**\n")
                report.append(f"```swift\n/// [Description of the {suggestion['name']} property]\n```\n")
        
        report.append(f"\nTotal documentation suggestions: {total_suggestions}\n")
        
        return "\n".join(report)
    
    def _get_type_name(self, name):
        """Guess the type name based on naming conventions."""
        if name.endswith('Controller'):
            return 'controller'
        elif name.endswith('Service'):
            return 'service'
        elif name.endswith('Manager'):
            return 'manager'
        elif name.endswith('View'):
            return 'view'
        elif name.endswith('ViewModel'):
            return 'view model'
        else:
            return 'class'

def main():
    parser = argparse.ArgumentParser(description='Generate documentation suggestions for Swift files')
    parser.add_argument('path', help='Path to a Swift file or directory')
    parser.add_argument('--analyze-only', action='store_true', help='Only analyze and output JSON statistics')
    args = parser.parse_args()
    
    path = Path(args.path)
    generator = DocumentationGenerator()
    
    if path.is_file() and path.suffix == '.swift':
        if args.analyze_only:
            _, stats = generator.analyze_file(path, analyze_only=True)
            print(json.dumps(stats))
        else:
            print(f"Analyzing {path}...")
            report = generator.generate_documentation_report(path)
            print(report)
    elif path.is_dir():
        if args.analyze_only:
            print("Directory analysis with --analyze-only is not supported. Please specify a single file.")
            sys.exit(1)
        for swift_file in path.glob('**/*.swift'):
            print(f"Analyzing {swift_file}...")
            report = generator.generate_documentation_report(swift_file)
            print(report)
    else:
        print(f"Error: {path} is not a valid Swift file or directory")
        sys.exit(1)

if __name__ == "__main__":
    main() 