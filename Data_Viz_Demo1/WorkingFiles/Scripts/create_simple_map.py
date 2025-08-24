#!/usr/bin/env python3
"""
Create a simple equirectangular base map - back to basics
"""

import geopandas as gpd
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

def create_base_map():
    print("Creating simple base map from Natural Earth data...")
    
    # Read the shapefile
    gdf = gpd.read_file("../RawData/ne_10m_admin_0_countries.shp")
    
    # Create figure with exact aspect ratio for equirectangular
    fig_width = 20.48  # 2048 pixels at 100 DPI
    fig_height = 10.24  # 1024 pixels at 100 DPI
    
    fig, ax = plt.subplots(figsize=(fig_width, fig_height), dpi=200)
    
    # Set up equirectangular projection bounds
    ax.set_xlim(-180, 180)
    ax.set_ylim(-90, 90)
    ax.set_aspect('equal')
    
    # Ocean/background color
    ocean_color = '#4A90E2'  # Nice blue
    land_color = '#90EE90'   # Light green
    
    # Fill background with ocean color
    ax.add_patch(Rectangle((-180, -90), 360, 180, 
                          facecolor=ocean_color, 
                          edgecolor='none', 
                          zorder=0))
    
    # Plot all countries with single color
    gdf.plot(ax=ax, 
            color=land_color, 
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
    plt.savefig('world_equirect_simple.png', 
                dpi=200, 
                bbox_inches='tight', 
                pad_inches=0)
    plt.close()
    
    print("✅ Created world_equirect_simple.png (4096x2048)")
    
    # Also create a smaller preview version
    fig, ax = plt.subplots(figsize=(10.24, 5.12), dpi=100)
    ax.set_xlim(-180, 180)
    ax.set_ylim(-90, 90)
    ax.set_aspect('equal')
    ax.add_patch(Rectangle((-180, -90), 360, 180, 
                          facecolor=ocean_color, 
                          edgecolor='none', 
                          zorder=0))
    gdf.plot(ax=ax, color=land_color, edgecolor='none', linewidth=0, zorder=1)
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
    plt.savefig('world_equirect_preview_simple.png', dpi=100, bbox_inches='tight', pad_inches=0)
    plt.close()
    
    print("✅ Created world_equirect_preview_simple.png (1024x512)")

if __name__ == "__main__":
    create_base_map()
