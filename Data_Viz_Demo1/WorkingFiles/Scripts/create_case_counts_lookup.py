#!/usr/bin/env python3
"""
Create a consolidated case counts lookup file for efficient real-time access.
This preserves actual case counts while keeping the binned data for visualization.
"""

import pandas as pd
import json
import os
from pathlib import Path

# Change to project directory
os.chdir('/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1')

# Output file
OUTPUT_FILE = Path('Data_Viz_Demo1/DataFiles/case_counts.json')

# Load all available raw data sources
def load_raw_data():
    all_data = {}
    
    # 1. Load new estimated case data (1980-2023)
    new_data_file = Path('Data_Viz_Demo1/WorkingFiles/FinalDataRaw/number-of-estimated-paralytic-polio-cases-by-world-region.csv')
    if new_data_file.exists():
        print(f"Loading estimated case data from {new_data_file}")
        df = pd.read_csv(new_data_file)
        
        # Filter out regional aggregates (only keep rows with country codes)
        df = df[df['Code'].notna()]
        
        # The new data has columns: Entity, Code, Year, Estimated polio cases
        if 'Estimated polio cases' in df.columns:
            for _, row in df.iterrows():
                if pd.notna(row['Code']) and pd.notna(row['Estimated polio cases']):
                    year = int(row['Year'])
                    code = row['Code']
                    # Handle float values in the data
                    cases = int(float(row['Estimated polio cases']))
                    
                    if year not in all_data:
                        all_data[year] = {}
                    all_data[year][code] = cases
        else:
            print("Warning: 'Estimated polio cases' column not found in data")
    
    # No need for additional data sources - the new file has complete data
    
    return all_data

def main():
    print("Creating consolidated case counts lookup file...")
    
    # Load all raw data
    case_data = load_raw_data()
    
    # Statistics
    total_entries = sum(len(year_data) for year_data in case_data.values())
    years = sorted(case_data.keys())
    
    print(f"\nLoaded data for {len(years)} years: {min(years)} to {max(years)}")
    print(f"Total country-year entries: {total_entries}")
    
    # Show sample data
    if 2023 in case_data:
        sample_countries = list(case_data[2023].items())[:5]
        print(f"\nSample data for 2023:")
        for code, cases in sample_countries:
            print(f"  {code}: {cases} cases")
    
    # Save as JSON for efficient lookup
    print(f"\nSaving to {OUTPUT_FILE}...")
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    # Convert to string keys for JSON
    case_data_str = {str(year): data for year, data in case_data.items()}
    
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(case_data_str, f, indent=2)
    
    print(f"Successfully created {OUTPUT_FILE}")
    print(f"File size: {OUTPUT_FILE.stat().st_size / 1024:.1f} KB")

if __name__ == "__main__":
    main()
