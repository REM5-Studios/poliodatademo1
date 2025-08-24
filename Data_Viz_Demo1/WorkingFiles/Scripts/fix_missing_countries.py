#!/usr/bin/env python3
"""
Find and add missing countries (FRA, NOR, REU) to centroids
"""

import json
import pandas as pd
import geopandas as gpd

# Read the shapefile to investigate
gdf = gpd.read_file("ne_10m_admin_0_countries.shp")

# Search for France, Norway, Reunion
print("Searching for missing countries in shapefile...")
print("\nFrance-related entries:")
france_mask = gdf['NAME'].str.contains('France', case=False, na=False) | \
              gdf['ADMIN'].str.contains('France', case=False, na=False) | \
              gdf['GEOUNIT'].str.contains('France', case=False, na=False)
print(gdf[france_mask][['NAME', 'ADMIN', 'ISO_A3', 'ADM0_A3', 'ISO_A3_EH']].head())

print("\nNorway-related entries:")
norway_mask = gdf['NAME'].str.contains('Norway', case=False, na=False) | \
              gdf['ADMIN'].str.contains('Norway', case=False, na=False) | \
              gdf['GEOUNIT'].str.contains('Norway', case=False, na=False)
print(gdf[norway_mask][['NAME', 'ADMIN', 'ISO_A3', 'ADM0_A3', 'ISO_A3_EH']].head())

print("\nReunion-related entries:")
reunion_mask = gdf['NAME'].str.contains('union', case=False, na=False) | \
               gdf['ADMIN'].str.contains('union', case=False, na=False) | \
               gdf['GEOUNIT'].str.contains('union', case=False, na=False)
print(gdf[reunion_mask][['NAME', 'ADMIN', 'ISO_A3', 'ADM0_A3', 'ISO_A3_EH']].head())

# Manual fixes based on knowledge
fixes = {
    'FRA': {'lon': 2.0, 'lat': 46.0, 'name': 'France'},  # Metropolitan France
    'NOR': {'lon': 8.0, 'lat': 61.0, 'name': 'Norway'},  
    'REU': {'lon': 55.5, 'lat': -21.1, 'name': 'Reunion'}  # La Réunion island
}

# Load existing centroids
with open('centroids.json', 'r') as f:
    centroids = json.load(f)

# Add missing countries
for code, data in fixes.items():
    if code not in centroids:
        x_norm = (data['lon'] + 180.0) / 360.0
        y_norm = (90.0 - data['lat']) / 180.0
        centroids[code] = [round(x_norm, 6), round(y_norm, 6)]
        print(f"Added {code} ({data['name']}): {centroids[code]}")

# Save updated centroids
with open('centroids.json', 'w') as f:
    json.dump(centroids, f, indent=2)

# Also update the CSV
centroids_df = pd.read_csv('centroids.csv')
for code, data in fixes.items():
    if code not in centroids_df['Code'].values:
        new_row = pd.DataFrame([{
            'Code': code,
            'lon': data['lon'],
            'lat': data['lat'],
            'x_norm': round((data['lon'] + 180.0) / 360.0, 6),
            'y_norm': round((90.0 - data['lat']) / 180.0, 6)
        }])
        centroids_df = pd.concat([centroids_df, new_row], ignore_index=True)

centroids_df = centroids_df.sort_values('Code')
centroids_df.to_csv('centroids.csv', index=False)

print(f"\nTotal countries in centroids: {len(centroids)}")
