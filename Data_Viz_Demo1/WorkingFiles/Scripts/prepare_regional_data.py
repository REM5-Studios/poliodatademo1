#!/usr/bin/env python3
"""
Prepare regional polio data for the visualization
"""

import pandas as pd
from pathlib import Path

# Define paths
SCRIPT_DIR = Path(__file__).parent
RAW_DATA_DIR = SCRIPT_DIR.parent / "RawData"
OUTPUT_DIR = SCRIPT_DIR.parent.parent / "DataFiles"

# Input files
INPUT_FILE = RAW_DATA_DIR / "number-of-estimated-paralytic-polio-cases-by-world-region.csv"
GLOBAL_TOTALS_FILE = RAW_DATA_DIR / "Global_Polio_Totals_Simplified__1980_2023_.csv"

def main():
    print(f"Loading data from {INPUT_FILE}")
    
    # Load the main dataset
    df = pd.read_csv(INPUT_FILE)
    
    # Get unique regions (entries without country codes)
    regions = df[df['Code'].isna()]['Entity'].unique()
    print(f"\nFound regions: {regions}")
    
    # Get unique years
    years = sorted(df['Year'].unique())
    print(f"\nYear range: {min(years)} - {max(years)}")
    
    # Create regional summary data
    regional_data = []
    
    # Get World totals from the existing data (not recalculated)
    world_totals = df[df['Entity'] == 'World'][['Entity', 'Year', 'Estimated polio cases']].copy()
    world_totals['Code'] = 'WORLD'
    
    # Add regional data (excluding World which we already have)
    regions_no_world = [r for r in regions if r != 'World']
    for region in regions_no_world:
        region_df = df[df['Entity'] == region][['Entity', 'Year', 'Estimated polio cases']].copy()
        region_df['Code'] = region.upper().replace(' ', '_')
        regional_data.append(region_df)
    
    # Combine all regional data with world totals
    regional_df = pd.concat([world_totals] + regional_data, ignore_index=True)
    regional_df = regional_df.rename(columns={'Estimated polio cases': 'cases'})
    
    # Load immunization data from global totals
    global_df = pd.read_csv(GLOBAL_TOTALS_FILE)
    
    # Merge immunization data
    regional_df = regional_df.merge(
        global_df[['Year', 'immunization_rate_pct']], 
        on='Year', 
        how='left'
    )
    
    # Reorder columns to match expected format: Year,cases,Entity,Code,immunization_rate_pct
    regional_df = regional_df[['Year', 'cases', 'Entity', 'Code', 'immunization_rate_pct']]
    
    # Save regional summary
    output_file = OUTPUT_DIR / "regional_polio_data.csv"
    regional_df.to_csv(output_file, index=False)
    print(f"\nSaved regional data to {output_file}")
    
    # Print summary
    print("\nRegional Summary:")
    all_regions = ['World'] + [r for r in regions if r != 'World']
    for region in all_regions:
        region_code = 'WORLD' if region == 'World' else region.upper().replace(' ', '_')
        region_data = regional_df[regional_df['Code'] == region_code]
        if not region_data.empty:
            total_cases = region_data['cases'].sum()
            print(f"  {region}: {total_cases:,.0f} total cases")

if __name__ == "__main__":
    main()
