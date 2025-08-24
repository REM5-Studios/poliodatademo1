#!/usr/bin/env python3
"""
Extract LABEL points (not centroids) from Natural Earth countries shapefile.
These are the coordinates specifically designed for placing labels on maps.
"""

import geopandas as gpd
import pandas as pd
from pathlib import Path
import sys
import os

def main():
    # Change to the directory with the shapefile
    os.chdir('/Users/amir/Downloads/ne_10m_admin_0_countries')
    
    # Read the shapefile
    print("Reading shapefile...")
    gdf = gpd.read_file("ne_10m_admin_0_countries.shp")
    
    print(f"Found {len(gdf)} countries in shapefile")
    
    # Use LABEL_X and LABEL_Y which are specifically for label placement
    if 'LABEL_X' not in gdf.columns or 'LABEL_Y' not in gdf.columns:
        print("ERROR: LABEL_X or LABEL_Y columns not found!")
        print("Available columns:", list(gdf.columns))
        return
    
    # Find the ISO_A3 column
    iso_col = None
    for col in ['ISO_A3', 'ISO_A3_EH', 'ADM0_A3']:
        if col in gdf.columns:
            iso_col = col
            break
    
    if not iso_col:
        print("ERROR: Could not find ISO_A3 column!")
        return
    
    print(f"Using {iso_col} for ISO3 codes")
    print("Using LABEL_X and LABEL_Y for coordinates")
    
    # Create output dataframe with required columns
    output_df = pd.DataFrame({
        'ISO_A3': gdf[iso_col],
        'LONGITUDE': gdf['LABEL_X'],
        'LATITUDE': gdf['LABEL_Y'],
        'NAME': gdf['NAME'] if 'NAME' in gdf.columns else gdf['ADMIN'] if 'ADMIN' in gdf.columns else 'Unknown'
    })
    
    # Filter out invalid ISO codes and missing label coordinates
    output_df = output_df[output_df['ISO_A3'].notna()]
    output_df = output_df[output_df['ISO_A3'] != '-99']
    output_df = output_df[output_df['ISO_A3'].str.len() == 3]
    output_df = output_df[output_df['LONGITUDE'].notna()]
    output_df = output_df[output_df['LATITUDE'].notna()]
    
    # Sort by ISO code
    output_df = output_df.sort_values('ISO_A3')
    
    print(f"\nFiltered to {len(output_df)} valid countries with label points")
    print("\nFirst 5 entries:")
    print(output_df.head())
    
    # Save to project directory
    output_file = "/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1/Data_Viz_Demo1/WorkingFiles/RawData/ne_admin0_label_points_corrected.csv"
    output_df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")
    
    # Show some key countries for verification
    print("\nLabel points for key countries:")
    key_countries = ['USA', 'GBR', 'FRA', 'DEU', 'AUS', 'BRA', 'CHN', 'IND']
    for code in key_countries:
        row = output_df[output_df['ISO_A3'] == code]
        if not row.empty:
            lon = row.iloc[0]['LONGITUDE']
            lat = row.iloc[0]['LATITUDE']
            name = row.iloc[0]['NAME']
            print(f"  {code} ({name}): {lon:.2f}, {lat:.2f}")

if __name__ == "__main__":
    main()
