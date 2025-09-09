#!/usr/bin/env python3
"""
Convert polio_timeline_categories.csv to JSON format for the app
"""

import csv
import json
import os

# Input and output paths
input_file = '../RawData/polio_timeline_categories.csv'
output_file = '../../DataFiles/polio_timeline_categories.json'

# Read CSV and convert to JSON
timeline_data = {}

with open(input_file, 'r', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    row_number = 0
    for row in reader:
        if row['category']:  # Skip empty rows
            # Using row number + 1980 as the year (since we have 47 entries for years 1980-2026)
            year = 1980 + row_number
            timeline_data[year] = {
                'category': row['category'],
                'headline': row['headline'],
                'subtext': row['subtext']
            }
            row_number += 1

# Write to JSON file
with open(output_file, 'w', encoding='utf-8') as jsonfile:
    json.dump(timeline_data, jsonfile, indent=2, ensure_ascii=False)

print(f"Successfully converted {len(timeline_data)} entries to {output_file}")
