#!/usr/bin/env python3
"""
Add missing countries to centroids.json
"""

import json
import csv

# Read countries.csv to get all required countries
with open('Data_Viz_Demo1/DataFiles/countries.csv', 'r') as f:
    reader = csv.DictReader(f)
    required_countries = {row['Code'] for row in reader}

# Read current centroids
with open('Data_Viz_Demo1/DataFiles/centroids.json', 'r') as f:
    centroids = json.load(f)

# Check what's missing
existing = set(centroids.keys())
missing = required_countries - existing

print(f"Required countries: {len(required_countries)}")
print(f"Existing in centroids: {len(existing)}")
print(f"Missing: {len(missing)}")

if missing:
    print(f"\nMissing countries: {sorted(missing)}")
    
    # Manual coordinates for missing countries
    manual_additions = {
        'FRA': [0.514, 0.252],  # France (approximately 2.3°E, 46.6°N)
        'NOR': [0.525, 0.168],  # Norway (approximately 9°E, 60°N)
        'REU': [0.654, 0.616],  # Réunion (approximately 55.5°E, -21°S)
    }
    
    # Add missing countries
    added = []
    for code in missing:
        if code in manual_additions:
            centroids[code] = manual_additions[code]
            added.append(code)
            print(f"Added {code}: {manual_additions[code]}")
        else:
            print(f"WARNING: No coordinates available for {code}")
    
    if added:
        # Save updated centroids
        with open('Data_Viz_Demo1/DataFiles/centroids.json', 'w') as f:
            json.dump(centroids, f, indent=2, sort_keys=True)
        print(f"\nUpdated centroids.json with {len(added)} countries")
else:
    print("\nAll countries are present!")
