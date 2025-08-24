#!/usr/bin/env python3
"""
Debug map coordinate system by plotting test points
"""

from PIL import Image, ImageDraw
import json
import csv

# Load the map
img = Image.open('Data_Viz_Demo1/WorkingFiles/world_equirect_preview_simple.png')
width, height = img.size
draw = ImageDraw.Draw(img)

# Load centroids
with open('Data_Viz_Demo1/DataFiles/centroids.json', 'r') as f:
    centroids = json.load(f)

# Load year 2000 data
with open('Data_Viz_Demo1/DataFiles/year_2000.csv', 'r') as f:
    reader = csv.DictReader(f)
    countries_2000 = {row['Code']: row['Bin'] for row in reader}

# Draw reference points
ref_points = [
    ('NW Corner', 0.0, 0.0, 'yellow'),
    ('NE Corner', 1.0, 0.0, 'yellow'),
    ('SW Corner', 0.0, 1.0, 'yellow'),
    ('SE Corner', 1.0, 1.0, 'yellow'),
    ('Center', 0.5, 0.5, 'yellow'),
]

for name, x_norm, y_norm, color in ref_points:
    x = int(x_norm * width)
    y = int(y_norm * height)
    draw.ellipse([x-10, y-10, x+10, y+10], fill=color, outline='black')
    draw.text((x+15, y-5), name, fill=color)

# Draw some key countries
test_countries = {
    'BRA': 'green',    # Brazil
    'USA': 'blue',     # USA
    'GBR': 'purple',   # UK
    'NGA': 'red',      # Nigeria (has polio in 2000)
    'IND': 'orange',   # India (has polio in 2000)
}

for code, color in test_countries.items():
    if code in centroids:
        x_norm, y_norm = centroids[code]
        x = int(x_norm * width)
        y = int(y_norm * height)
        
        # Draw dot
        draw.ellipse([x-5, y-5, x+5, y+5], fill=color, outline='black')
        draw.text((x+8, y-5), code, fill=color)
        
        # Check if has polio data
        if code in countries_2000:
            draw.text((x+8, y+10), f"Bin {countries_2000[code]}", fill=color)

# Save
img.save('Data_Viz_Demo1/WorkingFiles/debug_map_coordinates.png')
print("Saved debug map to Data_Viz_Demo1/WorkingFiles/debug_map_coordinates.png")

# Also print coordinate analysis
print("\nCoordinate analysis:")
print("If the map uses standard equirectangular projection:")
print("- Yellow dots should be at corners and center")
print("- Brazil (green) should be in South America")
print("- USA (blue) should be in North America")
print("- UK (purple) should be in Europe")
print("- Nigeria (red) should be in West Africa")
print("- India (orange) should be in South Asia")
