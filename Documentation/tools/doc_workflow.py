#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
import json
from pathlib import Path
from datetime import datetime

def print_header(text):
    """Print a formatted header."""
    print("\n" + "=" * 80)
    print(f" {text} ".center(80, "="))
    print("=" * 80 + "\n")

def run_command(command):
    """Run a command and return its output."""
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        print(f"stderr: {e.stderr}")
        return None

def analyze_file(file_path):
    """Analyze a single file and generate documentation suggestions."""
    print_header(f"Analyzing {file_path}")
    
    # Get the absolute path to the documentation generator
    script_dir = os.path.dirname(os.path.abspath(__file__))
    generator_path = os.path.join(script_dir, "documentation_generator_v2.py")
    
    # Get absolute path to the file
    abs_file_path = os.path.abspath(file_path)
    
    # Get the project root directory
    project_root = find_project_root(abs_file_path)
    if not project_root:
        print(f"Error: Could not determine project root for {abs_file_path}")
        return None
    
    # Get the relative path from the project root
    rel_path = os.path.relpath(abs_file_path, project_root)
    
    # Get file name without extension
    file_name = os.path.basename(file_path)
    base_name = os.path.splitext(file_name)[0]
    
    # Create the output directory structure that mirrors the codebase
    rel_dir = os.path.dirname(rel_path)
    output_dir = os.path.join(script_dir, "..", "reports", "suggestions", rel_dir)
    os.makedirs(output_dir, exist_ok=True)
    
    # Set the output file path
    output_file = os.path.join(output_dir, f"{base_name}_suggestions.md")
    
    # Run the documentation generator
    output = run_command([sys.executable, generator_path, abs_file_path])
    if output:
        print(output)
    
    # Save the output to a file
    if output:
        with open(output_file, "w") as f:
            f.write(output)
        
        print(f"Documentation suggestions saved to {os.path.abspath(output_file)}")
        return output_file
    
    return None

def audit_single_file(file_path):
    """Audit a single file and generate an audit report."""
    print_header(f"Auditing {file_path}")
    
    # Get the absolute path to the documentation audit script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    audit_path = os.path.join(script_dir, "documentation_audit.py")
    
    # Get absolute path to the file
    abs_file_path = os.path.abspath(file_path)
    
    # Get the project root directory
    project_root = find_project_root(abs_file_path)
    if not project_root:
        print(f"Error: Could not determine project root for {abs_file_path}")
        return None, None
    
    # Get the relative path from the project root
    rel_path = os.path.relpath(abs_file_path, project_root)
    
    # Get file name without extension
    file_name = os.path.basename(file_path)
    base_name = os.path.splitext(file_name)[0]
    
    # Create the output directory structure that mirrors the codebase
    rel_dir = os.path.dirname(rel_path)
    output_dir = os.path.join(script_dir, "..", "reports", "audits", rel_dir)
    os.makedirs(output_dir, exist_ok=True)
    
    # Set the output file path
    output_file = os.path.join(output_dir, f"{base_name}_audit.md")
    
    # Run the documentation generator in analysis mode
    generator_path = os.path.join(script_dir, "documentation_generator_v2.py")
    try:
        result = subprocess.run(
            [sys.executable, generator_path, abs_file_path, "--analyze-only"],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse the JSON output
        try:
            analysis = json.loads(result.stdout)
            
            # Generate a simple audit report for this file
            coverage = analysis.get('coverage_percentage', 0)
            total = analysis.get('total_items', 0)
            documented = analysis.get('documented_items', 0)
            
            report = []
            report.append(f"# Documentation Audit for {file_name}")
            report.append("")
            report.append(f"## Summary")
            report.append("")
            report.append(f"- **Coverage:** {coverage:.2f}%")
            report.append(f"- **Items:** {documented}/{total}")
            report.append("")
            
            # Add details about missing documentation
            if 'missing_documentation' in analysis and analysis['missing_documentation']:
                report.append("## Missing Documentation")
                report.append("")
                
                for item_type, items in analysis['missing_documentation'].items():
                    if items:
                        report.append(f"### {item_type.title()}")
                        for item in items:
                            report.append(f"- `{item}`")
                        report.append("")
            
            report_text = "\n".join(report)
            
            with open(output_file, 'w') as f:
                f.write(report_text)
            
            print(f"Audit report for {file_name} saved to {os.path.abspath(output_file)}")
            return output_file, analysis
            
        except json.JSONDecodeError:
            print(f"Error parsing JSON output for {file_path}")
            print(f"Output: {result.stdout}")
            return None, None
            
    except subprocess.CalledProcessError as e:
        print(f"Error analyzing {file_path}: {e}")
        print(f"stderr: {e.stderr}")
        return None, None

def run_audit(directory):
    """Run a documentation audit on a directory."""
    print_header(f"Running Documentation Audit on {directory}")
    
    # Get absolute path to the directory
    abs_directory_path = os.path.abspath(directory)
    
    # Check if this is a file instead of a directory
    if os.path.isfile(abs_directory_path):
        audit_file, _ = audit_single_file(abs_directory_path)
        return audit_file
    
    # Get the project root directory
    project_root = find_project_root(abs_directory_path)
    if not project_root:
        print(f"Error: Could not determine project root for {abs_directory_path}")
        return None
    
    # Get the relative path from the project root
    rel_path = os.path.relpath(abs_directory_path, project_root)
    
    # Create the output directory structure that mirrors the codebase
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "..", "reports", "audits", rel_path)
    os.makedirs(output_dir, exist_ok=True)
    
    # Find all Swift files
    swift_files = []
    for root, _, files in os.walk(abs_directory_path):
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(os.path.join(root, file))
    
    print(f"Found {len(swift_files)} Swift files to audit")
    
    # Audit each file
    file_stats = {}
    total_items = 0
    documented_items = 0
    
    for file_path in swift_files:
        rel_file_path = os.path.relpath(file_path, abs_directory_path)
        print(f"Auditing {rel_file_path}...")
        
        audit_file, analysis = audit_single_file(file_path)
        if analysis:
            file_stats[rel_file_path] = {
                'stats': analysis,
                'audit_file': audit_file
            }
            total_items += analysis.get('total_items', 0)
            documented_items += analysis.get('documented_items', 0)
    
    # Generate a summary report for the directory
    dir_name = os.path.basename(directory.rstrip('/'))
    summary_file = os.path.join(output_dir, f"{dir_name}_audit.md")
    
    # Calculate overall statistics
    coverage_percentage = (documented_items / total_items * 100) if total_items > 0 else 0
    
    # Sort files by documentation coverage (ascending)
    sorted_files = sorted(
        file_stats.items(),
        key=lambda x: x[1]['stats'].get('coverage_percentage', 0)
    )
    
    # Generate report
    report = []
    report.append("# Documentation Audit Report")
    report.append("")
    report.append(f"## Summary")
    report.append("")
    report.append(f"- **Files analyzed:** {len(file_stats)}")
    report.append(f"- **Total items:** {total_items}")
    report.append(f"- **Documented items:** {documented_items}")
    report.append(f"- **Overall coverage:** {coverage_percentage:.2f}%")
    report.append("")
    report.append("## Files by Coverage (Lowest to Highest)")
    report.append("")
    
    for file_path, file_data in sorted_files:
        stats = file_data['stats']
        audit_file = file_data['audit_file']
        coverage = stats.get('coverage_percentage', 0)
        total = stats.get('total_items', 0)
        documented = stats.get('documented_items', 0)
        
        # Create a relative path from the summary file to the audit file
        if audit_file:
            # Get the relative path from the summary file directory to the audit file
            audit_file_rel_path = os.path.relpath(audit_file, os.path.dirname(summary_file))
            # Create a markdown link to the audit file
            file_link = f"[{file_path}]({audit_file_rel_path})"
        else:
            file_link = file_path
        
        report.append(f"### {file_link}")
        report.append(f"- Coverage: {coverage:.2f}%")
        report.append(f"- Items: {documented}/{total}")
        report.append("")
    
    report_text = "\n".join(report)
    
    with open(summary_file, 'w') as f:
        f.write(report_text)
    
    print(f"Summary audit report saved to {os.path.abspath(summary_file)}")
    return summary_file

def find_project_root(path):
    """Find the project root directory by looking for common markers."""
    path = os.path.abspath(path)
    
    # If path is a file, get its directory
    if os.path.isfile(path):
        path = os.path.dirname(path)
    
    # Look for common project root markers
    markers = [
        "KoenjiApp",  # Your project name
        ".git",       # Git repository
        "Package.swift", # Swift package
        "project.pbxproj" # Xcode project
    ]
    
    # Start from the given path and move up until we find a marker
    current_path = path
    while current_path != os.path.dirname(current_path):  # Stop at filesystem root
        for marker in markers:
            if os.path.exists(os.path.join(current_path, marker)):
                # If the marker is a directory, return that directory
                if os.path.isdir(os.path.join(current_path, marker)) and marker == "KoenjiApp":
                    return os.path.join(current_path, marker)
                # Otherwise return the directory containing the marker
                return current_path
        
        # Move up one directory
        current_path = os.path.dirname(current_path)
    
    # If we couldn't find a project root, return None
    return None

def analyze_directory(directory):
    """Analyze all Swift files in a directory recursively."""
    print_header(f"Analyzing all files in {directory}")
    
    # Get absolute path to the directory
    abs_directory_path = os.path.abspath(directory)
    
    # Find all Swift files
    swift_files = []
    for root, _, files in os.walk(abs_directory_path):
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(os.path.join(root, file))
    
    print(f"Found {len(swift_files)} Swift files to analyze")
    
    # Analyze each file
    for file_path in swift_files:
        rel_path = os.path.relpath(file_path, abs_directory_path)
        print(f"Analyzing {rel_path}...")
        analyze_file(file_path)
    
    print(f"Completed analysis of {len(swift_files)} files")

def prioritize_files(audit_report):
    """Parse the audit report to identify files with low documentation coverage."""
    print_header("Prioritizing Files for Documentation")
    
    try:
        with open(audit_report, "r") as f:
            content = f.read()
        
        # Extract files with 0% coverage
        import re
        zero_coverage_files = re.findall(r"### (.*?)\n- Coverage: 0.00%", content)
        
        if zero_coverage_files:
            print("Files with 0% documentation coverage:")
            for file in zero_coverage_files:
                print(f"- {file}")
        else:
            print("No files with 0% documentation coverage found.")
        
        # Extract files with low coverage (below 20%)
        low_coverage_files = re.findall(r"### (.*?)\n- Coverage: ([0-9.]+)%", content)
        low_coverage_files = [(file, float(coverage)) for file, coverage in low_coverage_files if 0 < float(coverage) < 20]
        
        if low_coverage_files:
            print("\nFiles with low documentation coverage (below 20%):")
            for file, coverage in sorted(low_coverage_files, key=lambda x: x[1]):
                print(f"- {file} ({coverage:.2f}%)")
        else:
            print("\nNo files with low documentation coverage (below 20%) found.")
        
    except Exception as e:
        print(f"Error parsing audit report: {e}")

def main():
    parser = argparse.ArgumentParser(description="Documentation workflow tool")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Analyze command
    analyze_parser = subparsers.add_parser("analyze", help="Analyze a file and generate documentation suggestions")
    analyze_parser.add_argument("file", help="Path to the file to analyze")
    
    # Audit command
    audit_parser = subparsers.add_parser("audit", help="Run a documentation audit on a directory or file")
    audit_parser.add_argument("path", help="Directory or file to audit")
    
    # Audit-file command
    audit_file_parser = subparsers.add_parser("audit-file", help="Run a documentation audit on a single file")
    audit_file_parser.add_argument("file", help="File to audit")
    
    # Analyze-all command
    analyze_all_parser = subparsers.add_parser("analyze-all", help="Analyze all files in a directory recursively")
    analyze_all_parser.add_argument("directory", help="Directory to analyze")
    
    # Workflow command
    workflow_parser = subparsers.add_parser("workflow", help="Run a complete documentation workflow")
    workflow_parser.add_argument("directory", help="Directory to audit")
    workflow_parser.add_argument("--file", help="Optional specific file to analyze after the audit")
    workflow_parser.add_argument("--analyze-all", action="store_true", help="Analyze all files in the directory after the audit")
    
    args = parser.parse_args()
    
    if args.command == "analyze":
        analyze_file(args.file)
    elif args.command == "audit":
        run_audit(args.path)
    elif args.command == "audit-file":
        audit_single_file(args.file)
    elif args.command == "analyze-all":
        analyze_directory(args.directory)
    elif args.command == "workflow":
        audit_report = run_audit(args.directory)
        prioritize_files(audit_report)
        
        if args.analyze_all:
            analyze_directory(args.directory)
        elif args.file:
            analyze_file(args.file)
        else:
            print("\nTo analyze a specific file, run:")
            print(f"python3 {sys.argv[0]} analyze path/to/file.swift")
            print("\nTo analyze all files in a directory, run:")
            print(f"python3 {sys.argv[0]} analyze-all path/to/directory")
            print("\nOr add --analyze-all to the workflow command:")
            print(f"python3 {sys.argv[0]} workflow path/to/directory --analyze-all")
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 