#!/usr/bin/env python3
"""
Debug texture orientation by creating a test image with clear markers.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Change to project root
os.chdir('/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1')

# Create a test image with clear orientation markers
width = 1024
height = 512

img = Image.new('RGB', (width, height), 'lightblue')
draw = ImageDraw.Draw(img)

# Draw borders
draw.rectangle([0, 0, width-1, height-1], outline='black', width=3)

# Mark corners with text
font_size = 30
positions = [
    (10, 10, "TOP-LEFT\n(0,0)", 'red'),
    (width - 150, 10, "TOP-RIGHT\n(1,0)", 'green'),
    (10, height - 50, "BOTTOM-LEFT\n(0,1)", 'blue'),
    (width - 150, height - 50, "BOTTOM-RIGHT\n(1,1)", 'purple')
]

for x, y, text, color in positions:
    # Draw colored rectangle
    draw.rectangle([x, y, x+140, y+40], fill=color)
    draw.text((x+5, y+5), text, fill='white')

# Draw center cross
cx, cy = width//2, height//2
draw.line([cx-50, cy, cx+50, cy], fill='black', width=3)
draw.line([cx, cy-50, cx, cy+50], fill='black', width=3)
draw.text((cx+10, cy+10), "CENTER\n(0.5,0.5)", fill='black')

# Draw some reference points for known locations
# USA should be around (0.223, 0.293)
usa_x = int(0.223 * width)
usa_y = int(0.293 * height)
draw.ellipse([usa_x-10, usa_y-10, usa_x+10, usa_y+10], fill='orange', outline='darkorange')
draw.text((usa_x+15, usa_y-10), "USA", fill='orange')

# Save
output_path = 'Data_Viz_Demo1/WorkingFiles/texture_orientation_test.png'
img.save(output_path)
print(f"Created texture orientation test at: {output_path}")

# Also create a version at the actual resolution
img_hires = Image.new('RGB', (4096, 2048), 'lightblue')
draw_hires = ImageDraw.Draw(img_hires)

# Draw simple colored quadrants
colors = [
    ('red', 0, 0, 2048, 1024),      # Top-left
    ('green', 2048, 0, 4096, 1024), # Top-right
    ('blue', 0, 1024, 2048, 2048),  # Bottom-left
    ('purple', 2048, 1024, 4096, 2048) # Bottom-right
]

for color, x1, y1, x2, y2 in colors:
    draw_hires.rectangle([x1, y1, x2, y2], fill=color)

# Draw borders
draw_hires.rectangle([0, 0, 4095, 2047], outline='black', width=10)

# Save high-res version
hires_path = 'Data_Viz_Demo1/WorkingFiles/texture_test_4k.png'
img_hires.save(hires_path)
print(f"Created 4K texture test at: {hires_path}")
