#!/usr/bin/env python3
"""
Create a simple equirectangular base map from Natural Earth data
This ensures perfect alignment with our centroids
"""

import geopandas as gpd
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import numpy as np

def create_base_map():
    print("Creating base map from Natural Earth data...")
    
    # Read the shapefile
    gdf = gpd.read_file("../RawData/ne_10m_admin_0_countries.shp")
    
    # Create figure with exact aspect ratio for equirectangular
    # For 4096x2048 target: width should be 2x height
    fig_width = 40.96  # 4096 pixels at 100 DPI
    fig_height = 20.48  # 2048 pixels at 100 DPI
    
    fig, ax = plt.subplots(figsize=(fig_width, fig_height), dpi=100)
    
    # Set up equirectangular projection bounds
    ax.set_xlim(-180, 180)
    ax.set_ylim(-90, 90)
    ax.set_aspect('equal')
    
    # Ocean/background color - darker for more contrast
    ocean_color = '#1E5A8A'  # Darker blue
    
    # Define continent colors
    continent_colors = {
        'Africa': '#E67E22',       # Orange
        'Asia': '#E74C3C',         # Red
        'Europe': '#9B59B6',       # Purple
        'North America': '#3498DB', # Blue
        'South America': '#2ECC71', # Green
        'Oceania': '#F39C12',      # Gold
        'Antarctica': '#ECF0F1',   # Light gray
        'Seven seas (open ocean)': ocean_color
    }
    
    # Fill background with ocean color
    ax.add_patch(Rectangle((-180, -90), 360, 180, 
                          facecolor=ocean_color, 
                          edgecolor='none', 
                          zorder=0))
    
    # Plot countries by continent
    for continent, color in continent_colors.items():
        if continent != 'Seven seas (open ocean)':
            continent_data = gdf[gdf['CONTINENT'] == continent]
            if len(continent_data) > 0:
                continent_data.plot(ax=ax, 
                                  color=color, 
                                  edgecolor='none',  # No borders
                                  linewidth=0,
                                  zorder=1)
    
    # Remove all axes and margins
    ax.set_xticks([])
    ax.set_yticks([])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    
    # Save with no padding
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
    plt.savefig('world_equirect_4096x2048.png', 
                dpi=100, 
                bbox_inches='tight', 
                pad_inches=0)
    plt.close()
    
    print("✅ Created world_equirect_4096x2048.png")
    
    # Also create a smaller preview version (maintain 2:1 ratio)
    fig, ax = plt.subplots(figsize=(20.48, 10.24), dpi=50)
    ax.set_xlim(-180, 180)
    ax.set_ylim(-90, 90)
    ax.set_aspect('equal')
    ax.add_patch(Rectangle((-180, -90), 360, 180, 
                          facecolor=ocean_color, 
                          edgecolor='none', 
                          zorder=0))
    
    # Plot countries by continent (same as above)
    for continent, color in continent_colors.items():
        if continent != 'Seven seas (open ocean)':
            continent_data = gdf[gdf['CONTINENT'] == continent]
            if len(continent_data) > 0:
                continent_data.plot(ax=ax, 
                                  color=color, 
                                  edgecolor='none',
                                  linewidth=0,
                                  zorder=1)
    
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
    plt.savefig('world_equirect_preview.png', dpi=50, bbox_inches='tight', pad_inches=0)
    plt.close()
    
    print("✅ Created world_equirect_preview.png (1024x512)")

if __name__ == "__main__":
    create_base_map()
