#!/usr/bin/env python3
"""
Process polio data for years 1980-1999
Downloads from Our World in Data and formats for the app
"""

import pandas as pd
import requests
import json
import os
from pathlib import Path

# Define paths
SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR.parent.parent / "DataFiles"

# Our World in Data polio cases URL
OWID_POLIO_URL = "https://github.com/owid/owid-datasets/raw/master/datasets/Reported%20paralytic%20polio%20cases%20and%20deaths%20(WHO%202017)/Reported%20paralytic%20polio%20cases%20and%20deaths%20(WHO%202017).csv"

# Alternative URL if the above doesn't work
OWID_POLIO_ALT_URL = "https://raw.githubusercontent.com/owid/owid-datasets/master/datasets/Polio%20cases%20and%20deaths/Polio%20cases%20and%20deaths.csv"

def download_owid_data():
    """Download polio data from Our World in Data"""
    try:
        # Try primary URL first
        print(f"Attempting to download from primary URL...")
        response = requests.get(OWID_POLIO_URL)
        response.raise_for_status()
        return response.text
    except:
        print(f"Primary URL failed, trying alternative...")
        try:
            response = requests.get(OWID_POLIO_ALT_URL)
            response.raise_for_status()
            return response.text
        except Exception as e:
            print(f"ERROR: Could not download data: {e}")
            return None

def load_bins():
    """Load bin definitions"""
    bins_path = OUTPUT_DIR / "bins.csv"
    bins_df = pd.read_csv(bins_path)
    return bins_df

def get_bin_for_value(value, bins_df):
    """Determine which bin a value falls into"""
    if pd.isna(value) or value == 0:
        return 0
    
    for _, bin_row in bins_df.iterrows():
        if pd.isna(bin_row['EdgeMax']):  # Last bin
            return bin_row['Level']
        elif value <= bin_row['EdgeMax']:
            return bin_row['Level']
    
    return bins_df.iloc[-1]['Level']  # Default to highest bin

def main():
    print("Processing polio data for 1980-1999...")
    
    # Download data
    csv_data = download_owid_data()
    if not csv_data:
        print("Failed to download data. Please check the URLs or download manually.")
        return
    
    # Save raw data for inspection
    raw_file = SCRIPT_DIR / "owid_polio_raw.csv"
    with open(raw_file, 'w') as f:
        f.write(csv_data)
    print(f"Saved raw data to {raw_file}")
    
    # Load data
    from io import StringIO
    df = pd.read_csv(StringIO(csv_data))
    
    # Print columns to understand structure
    print(f"\nColumns in downloaded data: {df.columns.tolist()}")
    print(f"First few rows:")
    print(df.head())
    
    # Load bins for categorization
    bins_df = load_bins()
    
    # Process years 1980-1999
    years_to_process = range(1980, 2000)
    
    for year in years_to_process:
        # Filter data for this year
        year_col = str(year)
        if year_col not in df.columns:
            print(f"WARNING: Year {year} not found in data")
            continue
            
        # Get data for this year
        year_data = df[['Entity', 'Code', year_col]].copy()
        year_data = year_data.rename(columns={year_col: 'Value'})
        
        # Remove rows with no data
        year_data = year_data[year_data['Value'].notna()]
        year_data = year_data[year_data['Value'] > 0]
        
        if len(year_data) == 0:
            print(f"No data for year {year}")
            continue
            
        # Add bin values
        year_data['Bin'] = year_data['Value'].apply(lambda x: get_bin_for_value(x, bins_df))
        
        # Format as required (Code,Bin for 2-column format)
        output_data = year_data[['Code', 'Bin']].copy()
        
        # Save to file
        output_file = OUTPUT_DIR / f"year_{year}.csv"
        output_data.to_csv(output_file, index=False)
        print(f"Created {output_file} with {len(output_data)} countries")

if __name__ == "__main__":
    main()
