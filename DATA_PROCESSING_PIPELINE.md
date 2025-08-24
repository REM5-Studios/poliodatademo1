# Data Processing Pipeline - Quick Reference

## Step-by-Step Process to Regenerate Data

### Prerequisites
- Python 3.x with packages: `geopandas`, `pandas`, `matplotlib`, `pillow`, `shapely`
- Natural Earth shapefile: `ne_10m_admin_0_countries.shp`
- Raw polio data CSVs

### Pipeline Commands

```bash
# 1. Extract label points from shapefile
cd /Users/amir/Documents/Amir\ AVP\ 2025\ Projects/Data_Viz_Demo1
python3 Data_Viz_Demo1/WorkingFiles/Scripts/extract_label_points_from_shapefile.py

# 2. Generate normalized centroids
python3 Data_Viz_Demo1/WorkingFiles/Scripts/make_centroids_from_natural_earth.py \
    Data_Viz_Demo1/WorkingFiles/RawData/ne_admin0_label_points.csv \
    Data_Viz_Demo1/DataFiles/

# 3. Add missing countries (FRA, NOR, REU)
python3 Data_Viz_Demo1/WorkingFiles/Scripts/add_missing_countries_to_centroids.py

# 4. Generate map texture
python3 Data_Viz_Demo1/WorkingFiles/Scripts/create_simple_map.py

# 5. Verify data integrity
python3 Data_Viz_Demo1/WorkingFiles/Scripts/check_integrity_csv.py

# 6. (Optional) Verify visual alignment
python3 Data_Viz_Demo1/WorkingFiles/Scripts/verify_alignment.py
```

### Data Flow Diagram

```
Natural Earth Shapefile (.shp)
    ↓ [extract_label_points_from_shapefile.py]
ne_admin0_label_points.csv (LABEL_X, LABEL_Y)
    ↓ [make_centroids_from_natural_earth.py]
centroids.json + centroids.csv (normalized x,y)
    ↓ [add_missing_countries_to_centroids.py]
centroids.json (complete with FRA, NOR, REU)
    ↓
Final data ready for app
```

### Map Generation

```
create_simple_map.py
    ↓
world_equirect.png (4096x2048)
world_equirect_preview_simple.png (1024x512)
    ↓
Add to Assets.xcassets in Xcode
```

### Critical Files for App

Must be in `Data_Viz_Demo1/DataFiles/`:
- `bins.csv` - Height and color mapping
- `centroids.json` - Country positions
- `countries.csv` - List of all countries
- `year_2000.csv`, `year_2001.csv`, `year_2002.csv` - Case data

Must be in `Assets.xcassets`:
- `world_equirect.png` - Map texture

### Coordinate Transformation Reference

Geographic → Normalized:
```python
x_norm = (longitude + 180) / 360
y_norm = (90 - latitude) / 180
```

Normalized → RealityKit Local:
```swift
localX = (x_norm - 0.5) * mapWidth
localZ = (y_norm - 0.5) * mapHeight  // No inversion!
```
