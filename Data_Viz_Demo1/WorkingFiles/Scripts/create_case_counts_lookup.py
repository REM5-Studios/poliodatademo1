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
    
    # 1. Load OWID data (1980-2023)
    owid_file = Path('Data_Viz_Demo1/WorkingFiles/RawData/owid_polio_cases.csv')
    if owid_file.exists():
        print(f"Loading OWID data from {owid_file}")
        df = pd.read_csv(owid_file)
        
        # The OWID data has columns: Entity, Code, Year, Total polio cases
        if 'Total polio cases' in df.columns:
            for _, row in df.iterrows():
                if pd.notna(row['Code']) and pd.notna(row['Total polio cases']):
                    year = int(row['Year'])
                    code = row['Code']
                    cases = int(row['Total polio cases'])
                    
                    if year not in all_data:
                        all_data[year] = {}
                    all_data[year][code] = cases
        else:
            print("Warning: 'Total polio cases' column not found in OWID data")
    
    # 2. Load wide format data (2000-2002) - this might have more precise values
    wide_file = Path('Data_Viz_Demo1/WorkingFiles/RawData/polio_wide_values_2000_2002.csv')
    if wide_file.exists():
        print(f"Loading wide format data from {wide_file}")
        df = pd.read_csv(wide_file)
        
        # Override with these values as they might be more precise
        for year in ['2000', '2001', '2002']:
            if year in df.columns:
                year_int = int(year)
                if year_int not in all_data:
                    all_data[year_int] = {}
                    
                for _, row in df.iterrows():
                    if pd.notna(row['Code']) and pd.notna(row[year]):
                        code = row['Code']
                        cases = int(float(row[year]))
                        all_data[year_int][code] = cases
    
    # 3. Check for any other historical data files
    historical_file = Path('Data_Viz_Demo1/WorkingFiles/RawData/number-of-estimated-paralytic-polio-cases-by-world-region.csv')
    if historical_file.exists():
        print(f"Checking regional data from {historical_file}")
        # This file contains regional aggregates, not country-specific data
    
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
