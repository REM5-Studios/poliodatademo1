#!/usr/bin/env python3
"""
Verify that our centroids align with the generated map
"""

import json
import matplotlib.pyplot as plt
import matplotlib.image as mpimg

# Load centroids
with open('../../Resources/Data/centroids.json', 'r') as f:
    centroids = json.load(f)

# Load preview map
img = mpimg.imread('../world_equirect_preview_simple.png')

# Create plot
fig, ax = plt.subplots(figsize=(12, 6))
ax.imshow(img, extent=[-180, 180, -90, 90], aspect='auto')

# Plot a sample of centroids
sample_countries = ['USA', 'BRA', 'CHN', 'IND', 'FRA', 'AUS', 'RUS', 'ZAF', 'JPN', 'GBR']
for code in sample_countries:
    if code in centroids:
        x_norm, y_norm = centroids[code]
        # Convert normalized to degrees
        lon = x_norm * 360 - 180
        lat = 90 - y_norm * 180
        ax.plot(lon, lat, 'ro', markersize=8)
        ax.text(lon + 2, lat + 2, code, fontsize=10, color='red')

ax.set_xlim(-180, 180)
ax.set_ylim(-90, 90)
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')
ax.set_title('Centroid Alignment Verification')
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('../centroid_alignment_check.png', dpi=150)
plt.close()

print("✅ Created centroid_alignment_check.png")
print("Check this image to verify centroids are correctly positioned on countries")
