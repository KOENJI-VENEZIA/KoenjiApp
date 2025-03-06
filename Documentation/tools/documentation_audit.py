#!/usr/bin/env python3
import os
import re
import sys
import json
from collections import defaultdict
import subprocess
from pathlib import Path

# Configuration
PROJECT_ROOT = "KoenjiApp"
OUTPUT_FILE = "documentation_audit.md"
EXTENSIONS_TO_SCAN = [".swift"]
EXCLUDE_DIRS = ["Preview Content", "Tests", "Test Resources", "Previews"]

# Regex patterns for Swift
SWIFT_METHOD_PATTERN = r'(func|var|let)\s+(\w+)'
SWIFT_DOC_PATTERN = r'\/\/\/.*'

class DocumentationAudit:
    def __init__(self, root_dir=None):
        self.root_dir = root_dir or os.getcwd()
        self.swift_files = []
        self.documentation_stats = {}
        self.total_items = 0
        self.documented_items = 0
        
        # Get the absolute path to the documentation generator
        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.documentation_generator = os.path.join(script_dir, "documentation_generator_v2.py")
        
    def find_swift_files(self, directory=None):
        """Find all Swift files in the given directory recursively."""
        directory = directory or self.root_dir
        swift_files = []
        
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(os.path.join(root, file))
        
        self.swift_files = swift_files
        return swift_files
    
    def analyze_file(self, file_path):
        """Analyze a single Swift file for documentation coverage."""
        try:
            # Run the documentation generator in analysis mode
            result = subprocess.run(
                [sys.executable, self.documentation_generator, file_path, "--analyze-only"],
                capture_output=True,
                text=True,
                check=True
            )
            
            # Parse the JSON output
            try:
                analysis = json.loads(result.stdout)
                return analysis
            except json.JSONDecodeError:
                print(f"Error parsing JSON output for {file_path}")
                print(f"Output: {result.stdout}")
                return None
                
        except subprocess.CalledProcessError as e:
            print(f"Error analyzing {file_path}: {e}")
            print(f"stderr: {e.stderr}")
            return None
    
    def run_audit(self, directory=None):
        """Run the documentation audit on all Swift files."""
        if directory:
            self.root_dir = directory
            
        self.find_swift_files()
        
        print(f"Found {len(self.swift_files)} Swift files to analyze")
        
        for file_path in self.swift_files:
            rel_path = os.path.relpath(file_path, self.root_dir)
            print(f"Analyzing {rel_path}...")
            
            analysis = self.analyze_file(file_path)
            if analysis:
                self.documentation_stats[rel_path] = analysis
                
                # Update totals
                self.total_items += analysis.get('total_items', 0)
                self.documented_items += analysis.get('documented_items', 0)
        
        return self.documentation_stats
    
    def generate_report(self, output_file=None):
        """Generate a documentation coverage report."""
        if not self.documentation_stats:
            print("No documentation statistics available. Run audit first.")
            return
        
        # Calculate overall statistics
        coverage_percentage = (self.documented_items / self.total_items * 100) if self.total_items > 0 else 0
        
        # Sort files by documentation coverage (ascending)
        sorted_files = sorted(
            self.documentation_stats.items(),
            key=lambda x: x[1].get('coverage_percentage', 0)
        )
        
        # Generate report
        report = []
        report.append("# Documentation Audit Report")
        report.append("")
        report.append(f"## Summary")
        report.append("")
        report.append(f"- **Files analyzed:** {len(self.documentation_stats)}")
        report.append(f"- **Total items:** {self.total_items}")
        report.append(f"- **Documented items:** {self.documented_items}")
        report.append(f"- **Overall coverage:** {coverage_percentage:.2f}%")
        report.append("")
        report.append("## Files by Coverage (Lowest to Highest)")
        report.append("")
        
        for file_path, stats in sorted_files:
            coverage = stats.get('coverage_percentage', 0)
            total = stats.get('total_items', 0)
            documented = stats.get('documented_items', 0)
            
            report.append(f"### {file_path}")
            report.append(f"- Coverage: {coverage:.2f}%")
            report.append(f"- Items: {documented}/{total}")
            report.append("")
            
            # Add details about missing documentation
            if 'missing_documentation' in stats and stats['missing_documentation']:
                report.append("#### Missing Documentation")
                report.append("")
                
                for item_type, items in stats['missing_documentation'].items():
                    if items:
                        report.append(f"##### {item_type.title()}")
                        for item in items:
                            report.append(f"- `{item}`")
                        report.append("")
        
        report_text = "\n".join(report)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
            print(f"Report written to {output_file}")
        
        return report_text

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate a documentation audit report for Swift files")
    parser.add_argument("directory", nargs="?", default=None, help="Directory to analyze (default: current directory)")
    parser.add_argument("--output", "-o", default="documentation_audit_report.md", help="Output file for the report")
    
    args = parser.parse_args()
    
    audit = DocumentationAudit(args.directory)
    audit.run_audit()
    audit.generate_report(args.output) 