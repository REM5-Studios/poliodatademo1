#!/usr/bin/env python3
"""
Extract centroids from Natural Earth countries shapefile and create CSV
suitable for make_centroids_from_natural_earth.py script
"""

import geopandas as gpd
import pandas as pd
from pathlib import Path
import sys

def main():
    # Read the shapefile
    print("Reading shapefile...")
    gdf = gpd.read_file("ne_10m_admin_0_countries.shp")
    
    print(f"Found {len(gdf)} countries in shapefile")
    print("\nColumns available:", list(gdf.columns))
    
    # Get representative points (these are guaranteed to be inside the polygon)
    # For countries, this is often better than geometric centroids
    gdf['geometry'] = gdf.representative_point()
    
    # Extract coordinates
    gdf['LONGITUDE'] = gdf.geometry.x
    gdf['LATITUDE'] = gdf.geometry.y
    
    # Find the ISO_A3 column (might be named differently)
    iso_columns = [col for col in gdf.columns if 'ISO' in col.upper() and '3' in col]
    print(f"\nISO columns found: {iso_columns}")
    
    # Try to find the best ISO3 column
    iso_col = None
    for col in ['ISO_A3', 'ISO_A3_EH', 'ADM0_A3']:
        if col in gdf.columns:
            iso_col = col
            break
    
    if not iso_col:
        print("ERROR: Could not find ISO_A3 column!")
        print("Available columns:", list(gdf.columns))
        return
    
    print(f"Using {iso_col} for ISO3 codes")
    
    # Create output dataframe with required columns
    output_df = pd.DataFrame({
        'ISO_A3': gdf[iso_col],
        'LONGITUDE': gdf['LONGITUDE'],
        'LATITUDE': gdf['LATITUDE'],
        'NAME': gdf['NAME'] if 'NAME' in gdf.columns else gdf['ADMIN'] if 'ADMIN' in gdf.columns else 'Unknown'
    })
    
    # Filter out invalid ISO codes
    output_df = output_df[output_df['ISO_A3'].notna()]
    output_df = output_df[output_df['ISO_A3'] != '-99']
    output_df = output_df[output_df['ISO_A3'].str.len() == 3]
    
    # Sort by ISO code
    output_df = output_df.sort_values('ISO_A3')
    
    print(f"\nFiltered to {len(output_df)} valid countries")
    print("\nFirst 5 entries:")
    print(output_df.head())
    
    # Save to CSV
    output_file = "ne_admin0_label_points.csv"
    output_df.to_csv(output_file, index=False)
    print(f"\nSaved to {output_file}")
    
    # Show which countries are in our data
    our_countries = pd.read_csv("countries.csv")
    our_codes = set(our_countries['Code'])
    extracted_codes = set(output_df['ISO_A3'])
    
    missing = our_codes - extracted_codes
    if missing:
        print(f"\nWARNING: {len(missing)} countries from countries.csv not found in shapefile:")
        print(sorted(list(missing)))
    
    extra = extracted_codes - our_codes
    if extra:
        print(f"\nNote: {len(extra)} extra countries in shapefile not in countries.csv")

if __name__ == "__main__":
    main()
