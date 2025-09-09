#!/usr/bin/env python3
"""
Convert polio_timeline.csv to JSON format for the app
"""

import csv
import json
import os

# Input and output paths
input_file = '../RawData/polio_timeline.csv'
output_file = '../../DataFiles/polio_timeline.json'

# Read CSV and convert to JSON
timeline_data = {}

with open(input_file, 'r', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if row['year']:  # Skip empty rows
            year = int(row['year'])
            # Remove "Defining Moment: " prefix from headline
            headline = row['headline']
            if headline.startswith("Defining Moment: "):
                headline = headline[17:]  # Remove the prefix
            
            timeline_data[year] = {
                'headline': headline,
                'stat': row['stat'],
                'photo': row['photo']  # Keep photo field for potential future use
            }

# Write to JSON file
with open(output_file, 'w', encoding='utf-8') as jsonfile:
    json.dump(timeline_data, jsonfile, indent=2, ensure_ascii=False)

print(f"Successfully converted {len(timeline_data)} entries to {output_file}")
