#!/usr/bin/env python3
"""
Process historical polio data from 1980-1999
Using data downloaded from Our World in Data
"""

import pandas as pd
from pathlib import Path

# Define paths
SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR.parent.parent
OUTPUT_DIR = DATA_DIR / "DataFiles"
INPUT_FILE = DATA_DIR / "owid_polio_cases.csv"

def load_bins():
    """Load bin definitions"""
    bins_path = OUTPUT_DIR / "bins.csv"
    bins_df = pd.read_csv(bins_path)
    return bins_df

def get_bin_for_value(value, bins_df):
    """Determine which bin a value falls into"""
    if pd.isna(value) or value == 0:
        return 0
    
    # Skip bin 0 which has NaN edge_max
    for _, bin_row in bins_df[bins_df['bin'] > 0].iterrows():
        if pd.isna(bin_row['edge_max']):  # Last bin (highest)
            return bin_row['bin']
        elif value <= bin_row['edge_max']:
            return bin_row['bin']
    
    return bins_df.iloc[-1]['bin']  # Default to highest bin

def main():
    print("Processing historical polio data for 1980-1999...")
    
    # Load data
    df = pd.read_csv(INPUT_FILE)
    print(f"Loaded {len(df)} rows of data")
    print(f"Years available: {df['Year'].min()} to {df['Year'].max()}")
    
    # Load bins for categorization
    bins_df = load_bins()
    
    # Process years 1980-1999
    years_to_process = range(1980, 2000)
    processed_count = 0
    problematic_countries = set()
    
    for year in years_to_process:
        # Filter data for this year
        year_data = df[df['Year'] == year].copy()
        
        if len(year_data) == 0:
            print(f"WARNING: No data for year {year}")
            continue
        
        # Remove rows with no data or zero cases
        year_data = year_data[year_data['Total polio cases'].notna()]
        year_data = year_data[year_data['Total polio cases'] > 0]
        
        # Check for missing country codes
        missing_codes = year_data[year_data['Code'].isna()]
        if len(missing_codes) > 0:
            for _, row in missing_codes.iterrows():
                problematic_countries.add(row['Entity'])
            year_data = year_data[year_data['Code'].notna()]
        
        if len(year_data) == 0:
            print(f"No valid data for year {year} after filtering")
            continue
        
        # Add bin values
        year_data['Bin'] = year_data['Total polio cases'].apply(
            lambda x: get_bin_for_value(x, bins_df)
        )
        
        # Format as required (Code,Bin for 2-column format)
        output_data = year_data[['Code', 'Bin']].copy()
        
        # Save to file
        output_file = OUTPUT_DIR / f"year_{year}.csv"
        output_data.to_csv(output_file, index=False)
        print(f"Created {output_file.name} with {len(output_data)} countries")
        processed_count += 1
    
    print(f"\nProcessed {processed_count} years successfully")
    
    if problematic_countries:
        print(f"\nWARNING: Found {len(problematic_countries)} countries without codes:")
        for country in sorted(problematic_countries):
            print(f"  - {country}")
        print("\nThese countries were excluded from the output files.")
    
    # Show summary statistics
    print("\nSummary of cases by decade:")
    df_filtered = df[df['Year'].between(1980, 1999)]
    df_filtered['Decade'] = (df_filtered['Year'] // 10) * 10
    decade_summary = df_filtered.groupby('Decade')['Total polio cases'].agg(['sum', 'count'])
    print(decade_summary)

if __name__ == "__main__":
    main()
