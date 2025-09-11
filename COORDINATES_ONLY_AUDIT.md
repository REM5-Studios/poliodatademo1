# Coordinates-Only Audit

Since you only need country coordinates and don't plan to regenerate maps, here's what you actually need:

## The ONLY File Your App Uses for Coordinates

✅ **`DataFiles/centroids.json`** - This is it! The app loads country positions from this single file.

Format:
```json
{
  "AFG": [0.684713, 0.310199],  // x, y normalized coordinates (0-1 range)
  "PAK": [0.698543, 0.334123],
  // ... etc for all countries
}
```

## Everything Else Can Be Removed

Since you're not regenerating maps or coordinates, you can safely remove:

### All Map Generation Files
- ❌ `create_base_map.py`
- ❌ `create_simple_map.py`
- ❌ All PNG files in WorkingFiles directory
- ❌ The map texture is already in Assets.xcassets

### All Coordinate Generation Files
- ❌ `extract_label_points_from_shapefile.py`
- ❌ `extract_centroids_from_shapefile.py`
- ❌ `make_centroids_from_natural_earth.py`
- ❌ `add_missing_countries_to_centroids.py`
- ❌ `fix_missing_countries.py`

### All Natural Earth Shapefile Data
- ❌ `ne_10m_admin_0_countries.shp`
- ❌ `ne_10m_admin_0_countries.shx`
- ❌ `ne_10m_admin_0_countries.dbf`
- ❌ `ne_10m_admin_0_countries.prj`
- ❌ `ne_10m_admin_0_countries.cpg`
- ❌ `ne_10m_admin_0_countries.README.html`
- ❌ `ne_10m_admin_0_countries.VERSION.txt`

### Intermediate Coordinate Files
- ❌ `ne_admin0_label_points.csv`
- ❌ `ne_admin0_label_points_corrected.csv`
- ❌ `centroids.csv` (the JSON version is what's used)

### Debug/Verification Scripts (Optional to Remove)
- ❌ `verify_alignment.py`
- ❌ `check_bar_alignment.py`
- ❌ `debug_map_coordinates.py`
- ❌ `debug_texture_orientation.py`

## What You Keep

1. ✅ **`DataFiles/centroids.json`** - The ONLY coordinate file your app needs
2. ✅ **`Assets.xcassets/world_equirect.png`** - The map texture your app displays

## Important Note

If you ever need to:
- Add a new country
- Fix a country's position
- Update for border changes

You would need to manually edit `centroids.json` with the normalized x,y coordinates (0-1 range where 0,0 is top-left and 1,1 is bottom-right of the map).

## Space Savings

Removing all the shapefile data and scripts will free up significant space since shapefiles are quite large.
