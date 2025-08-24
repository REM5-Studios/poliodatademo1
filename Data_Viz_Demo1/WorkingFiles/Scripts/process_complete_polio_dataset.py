#!/usr/bin/env python3
"""
Process complete polio dataset from 1980-2023
Using comprehensive data from Our World in Data
"""

import pandas as pd
from pathlib import Path
import numpy as np

# Define paths
SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR.parent.parent
OUTPUT_DIR = DATA_DIR / "DataFiles"
INPUT_FILE = SCRIPT_DIR.parent / "RawData" / "number-of-estimated-paralytic-polio-cases-by-world-region.csv"

# Backup existing data
BACKUP_DIR = DATA_DIR / "DataFiles_backup_before_complete_update"

def backup_existing_data():
    """Backup existing year files before overwriting"""
    if not BACKUP_DIR.exists():
        BACKUP_DIR.mkdir(parents=True)
        print(f"Created backup directory: {BACKUP_DIR}")
        
        # Copy existing year files
        import shutil
        for year in range(1980, 2024):
            src = OUTPUT_DIR / f"year_{year}.csv"
            if src.exists():
                dst = BACKUP_DIR / f"year_{year}.csv"
                shutil.copy2(src, dst)
                print(f"Backed up {src.name}")

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
    print("Processing complete polio dataset for 1980-2023...")
    
    # Backup existing data first
    backup_existing_data()
    
    # Load data
    df = pd.read_csv(INPUT_FILE)
    print(f"Loaded {len(df)} rows of data")
    
    # Filter out regional/world aggregates (rows without country codes)
    df_countries = df[df['Code'].notna()].copy()
    print(f"Found {len(df_countries)} country-specific entries")
    
    # Check for unique countries
    countries = df_countries['Entity'].unique()
    print(f"Found {len(countries)} unique countries")
    
    # Load bins for categorization
    bins_df = load_bins()
    
    # Track statistics
    all_years = sorted(df_countries['Year'].unique())
    print(f"Years in dataset: {min(all_years)} to {max(all_years)}")
    
    processed_count = 0
    empty_years = []
    problematic_countries = set()
    country_changes = {}
    
    # Process each year
    for year in range(1980, 2024):
        # Filter data for this year
        year_data = df_countries[df_countries['Year'] == year].copy()
        
        if len(year_data) == 0:
            print(f"WARNING: No data for year {year}")
            empty_years.append(year)
            continue
        
        # Check for duplicate country codes
        duplicates = year_data[year_data.duplicated(subset=['Code'], keep=False)]
        if len(duplicates) > 0:
            print(f"\nWARNING: Duplicate codes in {year}:")
            for code in duplicates['Code'].unique():
                entries = year_data[year_data['Code'] == code]
                print(f"  {code}: {entries['Entity'].tolist()}")
                problematic_countries.update(entries['Entity'].tolist())
            # Keep first occurrence of each code
            year_data = year_data.drop_duplicates(subset=['Code'], keep='first')
        
        # Track country name changes
        for _, row in year_data.iterrows():
            code = row['Code']
            entity = row['Entity']
            if code not in country_changes:
                country_changes[code] = set()
            country_changes[code].add(entity)
        
        # Remove rows with no data or zero cases
        year_data = year_data[year_data['Estimated polio cases'].notna()]
        year_data = year_data[year_data['Estimated polio cases'] > 0]
        
        if len(year_data) == 0:
            print(f"No cases reported for year {year}")
            # Create empty file to maintain consistency
            output_data = pd.DataFrame(columns=['Code', 'Bin'])
        else:
            # Add bin values
            year_data['Bin'] = year_data['Estimated polio cases'].apply(
                lambda x: get_bin_for_value(x, bins_df)
            )
            
            # Format as required (Code,Bin for 2-column format)
            output_data = year_data[['Code', 'Bin']].copy()
        
        # Save to file
        output_file = OUTPUT_DIR / f"year_{year}.csv"
        output_data.to_csv(output_file, index=False)
        print(f"Created {output_file.name} with {len(output_data)} countries")
        processed_count += 1
    
    print(f"\n{'='*60}")
    print(f"PROCESSING COMPLETE")
    print(f"{'='*60}")
    print(f"Processed {processed_count} years successfully")
    
    if empty_years:
        print(f"\nYears with no data: {empty_years}")
    
    # Report country name changes
    name_changes = {code: names for code, names in country_changes.items() if len(names) > 1}
    if name_changes:
        print(f"\nCountries with name variations:")
        for code, names in sorted(name_changes.items()):
            print(f"  {code}: {' / '.join(sorted(names))}")
    
    if problematic_countries:
        print(f"\nProblematic countries (duplicates or other issues):")
        for country in sorted(problematic_countries):
            print(f"  - {country}")
    
    # Summary statistics
    print("\nSummary of cases by decade:")
    df_countries['Decade'] = (df_countries['Year'] // 10) * 10
    decade_summary = df_countries.groupby('Decade')['Estimated polio cases'].agg(['sum', 'count', 'mean'])
    decade_summary['sum'] = decade_summary['sum'].astype(int)
    decade_summary['mean'] = decade_summary['mean'].round(0).astype(int)
    print(decade_summary)
    
    # Year-over-year change
    print("\nDramatic changes:")
    total_1980 = df_countries[df_countries['Year'] == 1980]['Estimated polio cases'].sum()
    total_2023 = df_countries[df_countries['Year'] == 2023]['Estimated polio cases'].sum()
    print(f"1980: {int(total_1980):,} total cases")
    print(f"2023: {int(total_2023):,} total cases")
    print(f"Reduction: {((total_1980 - total_2023) / total_1980 * 100):.1f}%")

if __name__ == "__main__":
    main()
