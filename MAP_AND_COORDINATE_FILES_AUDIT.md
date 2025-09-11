# Map and Coordinate Files Audit

## Overview
The app uses a map texture and coordinate system to place 3D bars. This audit identifies what's essential vs redundant.

## Essential Files (MUST KEEP)

### 1. Natural Earth Shapefile Components
These files work together as a unit - ALL are required for shapefile reading:
- `ne_10m_admin_0_countries.shp` - Main shapefile (geometry data)
- `ne_10m_admin_0_countries.shx` - Shape index
- `ne_10m_admin_0_countries.dbf` - Attribute data
- `ne_10m_admin_0_countries.prj` - Projection information
- `ne_10m_admin_0_countries.cpg` - Character encoding

**Why needed**: Source data for both map generation AND centroid extraction. Even if you don't regenerate the map, you might need to add new countries or fix positions.

### 2. Final Map Texture
- `Assets.xcassets/world_equirect.imageset/world_equirect.png` - Used by the app

### 3. Generated Coordinate Data
- `DataFiles/centroids.json` - Country positions used by the app
- `DataFiles/centroids.csv` - CSV version (backup/reference)

## Redundant/Removable Files

### 1. Duplicate Map Generation Scripts
We have TWO scripts that do the same thing:
- `create_base_map.py` - Creates map with colored continents
- `create_simple_map.py` - Creates simpler map with single land color

**Recommendation**: Keep only `create_simple_map.py` (referenced in documentation)

### 2. Intermediate/Working Files
- `world_equirect_preview_simple.png` - Preview version not used by app
- `debug_map_coordinates.png` - Debug output
- Any `world_equirect_*.png` files NOT in Assets.xcassets

### 3. Redundant Coordinate Scripts
- `extract_centroids_from_shapefile.py` - Old approach using geometric centroids
- Keep: `extract_label_points_from_shapefile.py` - Current approach using label points

### 4. Documentation Files (Can Remove)
- `ne_10m_admin_0_countries.README.html` - Natural Earth documentation
- `ne_10m_admin_0_countries.VERSION.txt` - Version info

## Files to Keep for Future Updates

### Essential Scripts for Updates
1. `extract_label_points_from_shapefile.py` - Extract country positions
2. `make_centroids_from_natural_earth.py` - Convert to normalized coordinates
3. `add_missing_countries_to_centroids.py` - Add missing countries
4. `create_simple_map.py` - Generate map texture

### Verification Scripts (Keep)
- `verify_alignment.py` - Visual verification
- `check_bar_alignment.py` - Bar position checking
- `debug_map_coordinates.py` - Coordinate debugging

## Summary

### Can Safely Remove
1. ❌ `create_base_map.py` - Duplicate map generation
2. ❌ `extract_centroids_from_shapefile.py` - Old centroid approach
3. ❌ `world_equirect_preview_simple.png` - Unused preview
4. ❌ `ne_10m_admin_0_countries.README.html` - Documentation
5. ❌ `ne_10m_admin_0_countries.VERSION.txt` - Version info
6. ❌ Any debug PNG files in WorkingFiles

### Must Keep
1. ✅ All `.shp`, `.shx`, `.dbf`, `.prj`, `.cpg` files - Complete shapefile set
2. ✅ `world_equirect.png` in Assets.xcassets - App uses this
3. ✅ `centroids.json` - App uses this
4. ✅ Current pipeline scripts - For future updates

## Important Notes

1. **Shapefile Components**: Never delete individual shapefile components (.shp, .shx, .dbf, .prj, .cpg) - they must stay together as a set.

2. **Map Regeneration**: If you update the map design, you only need `create_simple_map.py` and the shapefile.

3. **Coordinate Updates**: The pipeline for updating coordinates is:
   - Shapefile → extract_label_points → make_centroids → add_missing_countries → centroids.json

4. **No Redundancy**: After cleanup, each script will have a unique purpose in the pipeline.
