#!/usr/bin/env python3

"""
Script to convert markdown image syntax to HTML img tags
Usage: python convert_md_images_to_html.py [directory]
"""

import re
import sys
from pathlib import Path


def convert_line(line):
    """
    Convert markdown image syntax to HTML img tags in a line.
    Returns tuple: (converted_line, conversion_count)
    """
    # Pattern to match markdown image syntax: ![alt text](url)
    pattern = r"!\[([^\]]*)\]\(([^)]+)\)"

    conversions = 0

    def replace_func(match):
        nonlocal conversions
        alt_text = match.group(1)
        url = match.group(2)
        conversions += 1
        return f'<img src="{url}" alt="{alt_text}">'

    converted_line = re.sub(pattern, replace_func, line)

    return converted_line, conversions


def process_file(file_path):
    """
    Process a single markdown file, converting all markdown images to HTML.
    Returns the number of conversions made.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()

        new_lines = []
        total_conversions = 0

        for line in lines:
            converted_line, conversions = convert_line(line)
            new_lines.append(converted_line)
            total_conversions += conversions

        # Only write back if conversions were made
        if total_conversions > 0:
            with open(file_path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)

        return total_conversions

    except Exception as e:
        print(f"  ✗ Error processing file: {e}")
        return 0


def main():
    # Get target directory from command line argument or use current directory
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    target_path = Path(target_dir)

    if not target_path.exists():
        print(f"Error: Directory '{target_dir}' does not exist")
        sys.exit(1)

    print(f"Starting conversion in directory: {target_path.absolute()}")
    print("=" * 60)

    # Statistics
    total_files_modified = 0
    total_conversions = 0

    # Find all markdown files recursively
    md_files = list(target_path.rglob("*.md"))

    if not md_files:
        print("No markdown files found.")
        return

    print(f"Found {len(md_files)} markdown file(s)\n")

    for md_file in md_files:
        print(f"Processing: {md_file.relative_to(target_path)}")

        conversions = process_file(md_file)

        if conversions > 0:
            print(f"  ✓ Converted {conversions} image(s)")
            total_files_modified += 1
            total_conversions += conversions
        else:
            print("  - No images found")

    print("\n" + "=" * 60)
    print("Conversion complete!")
    print(f"Files modified: {total_files_modified}")
    print(f"Total images converted: {total_conversions}")


if __name__ == "__main__":
    main()
