#!/usr/bin/env python3
"""
Check if bar positions align with the map by overlaying centroids on the map image.
"""

import json
from PIL import Image, ImageDraw
import os

# Change to project root
os.chdir('/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1')

# Load centroids
with open('Data_Viz_Demo1/DataFiles/centroids.json', 'r') as f:
    centroids = json.load(f)

# Load year data to see which countries have data
with open('Data_Viz_Demo1/DataFiles/year_2000.csv', 'r') as f:
    lines = f.readlines()[1:]  # Skip header
    countries_with_data = set()
    for line in lines:
        parts = line.strip().split(',')
        if len(parts) >= 2:
            countries_with_data.add(parts[0])

# Load the preview map
img = Image.open('Data_Viz_Demo1/WorkingFiles/world_equirect_preview_simple.png')
width, height = img.size

# Create a copy to draw on
img_with_dots = img.copy()
draw = ImageDraw.Draw(img_with_dots)

# Draw dots for countries with data
for code in countries_with_data:
    if code in centroids:
        x_norm, y_norm = centroids[code]
        # Convert to pixel coordinates
        x_pixel = int(x_norm * width)
        y_pixel = int(y_norm * height)
        
        # Draw a red dot
        radius = 3
        draw.ellipse([x_pixel-radius, y_pixel-radius, x_pixel+radius, y_pixel+radius], 
                     fill='red', outline='darkred')

# Draw some reference countries in blue
reference_countries = ['USA', 'GBR', 'JPN', 'AUS', 'BRA', 'IND', 'CHN', 'RUS']
for code in reference_countries:
    if code in centroids:
        x_norm, y_norm = centroids[code]
        x_pixel = int(x_norm * width)
        y_pixel = int(y_norm * height)
        
        # Draw a blue dot
        radius = 5
        draw.ellipse([x_pixel-radius, y_pixel-radius, x_pixel+radius, y_pixel+radius], 
                     fill='blue', outline='darkblue')
        
        # Add label
        draw.text((x_pixel + 8, y_pixel - 5), code, fill='blue')

# Save the result
output_path = 'Data_Viz_Demo1/WorkingFiles/bar_alignment_check.png'
img_with_dots.save(output_path)
print(f"Saved alignment check to: {output_path}")

# Also check the coordinate transformation logic
print("\nChecking coordinate transformation for key countries:")
map_width = 1.2
map_height = 0.6

for code in ['USA', 'GBR', 'AUS', 'BRA']:
    if code in centroids:
        x_norm, y_norm = centroids[code]
        # This is what the Swift code does
        localX = (x_norm - 0.5) * map_width
        localZ = (0.5 - y_norm) * map_height
        print(f"{code}: normalized({x_norm:.3f}, {y_norm:.3f}) -> local({localX:.3f}, {localZ:.3f})")
