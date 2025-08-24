# Polio Data Visualization for Apple Vision Pro - Complete Documentation

## Project Overview
A visionOS application that creates an immersive 3D tabletop visualization of global polio cases from 2000-2002, displaying data as 3D bars rising from country locations on a world map.

## Table of Contents
1. [Data Pipeline](#data-pipeline)
2. [Map Generation](#map-generation)
3. [visionOS App Development](#visionos-app-development)
4. [Coordinate System](#coordinate-system)
5. [Troubleshooting & Solutions](#troubleshooting--solutions)
6. [File Structure](#file-structure)
7. [Technical Details](#technical-details)

---

## 1. Data Pipeline

### 1.1 Source Data
- **Natural Earth Data**: Downloaded `ne_10m_admin_0_countries` shapefile for country boundaries and label points
- **Polio Data**: CSV files with reported paralytic polio cases for years 2000-2002

### 1.2 Centroid Extraction Process

#### Step 1: Extract Label Points from Shapefile
```python
# extract_label_points_from_shapefile.py
- Read Natural Earth shapefile using geopandas
- Extract LABEL_X and LABEL_Y (NOT geometric centroids)
- Filter for valid ISO-3 country codes
- Output: ne_admin0_label_points.csv
```

**Key Learning**: Use label points instead of geometric centroids for better visual placement (e.g., USA at continental center, not including Alaska).

#### Step 2: Generate Normalized Centroids
```python
# make_centroids_from_natural_earth.py
- Convert longitude/latitude to normalized coordinates:
  x_norm = (longitude + 180) / 360
  y_norm = (90 - latitude) / 180
- Output: centroids.json and centroids.csv
```

#### Step 3: Add Missing Countries
```python
# add_missing_countries_to_centroids.py
- Manually added FRA, NOR, REU with appropriate coordinates
- These were missing from the Natural Earth dataset
```

### 1.3 Data Validation
```python
# check_integrity_csv.py
- Verified all countries in countries.csv have centroids
- Checked year data files match expected format
- Validated bin assignments
```

---

## 2. Map Generation

### 2.1 Map Creation Process
```python
# create_simple_map.py
- Generated equirectangular projection world map
- Single color for land (light green #8FBC8F)
- Ocean color (blue #4682B4)
- No country borders for clean visualization
- Resolution: 4096x2048 (2:1 aspect ratio)
- Also created 1024x512 preview version
```

### 2.2 Coordinate Verification
```python
# verify_alignment.py
- Overlaid centroid points on map to verify alignment
- Created visual debug images with country markers
```

---

## 3. visionOS App Development

### 3.1 Project Setup
- **Target**: visionOS 2.5+ (Apple Vision Pro only)
- **Frameworks**: SwiftUI, RealityKit
- **Structure**: ImmersiveSpace for 3D visualization, WindowGroup for controls

### 3.2 Core Components

#### DataLoader.swift
```swift
- Loads CSV and JSON data files
- Parses bins.csv for height/color mapping
- Loads countries.csv for country list
- Loads centroids.json for positions
- Loads year-specific data (year_YYYY.csv)
```

#### MapScene.swift
```swift
- Creates RealityKit scene with:
  - World anchor at table height (0.75m)
  - Map rig for gesture control
  - Map plane (1.2m x 0.6m) with texture
  - Bars container for 3D bar entities

- Key transformations:
  let localX = (normalizedPos.x - 0.5) * mapWidth
  let localZ = (normalizedPos.y - 0.5) * mapHeight
```

#### ContentView.swift & ControlPanel.swift
```swift
- Year selector UI in 2D window
- NotificationCenter for year changes
- Communicates with immersive space
```

### 3.3 Entity Hierarchy
```
WorldAnchor (world position: [0, 0.75, -1.0])
└── MapRig (handles gestures)
    ├── MapPlane (rotated -90° around X)
    └── BarsRoot
        └── Individual Bar Entities
```

**Critical**: Bars are siblings of MapPlane, not children, to avoid inheriting rotation.

### 3.4 Gesture Handling
- **Drag**: Translates map on XZ plane
- **Rotate**: Rotates around Y axis
- **Magnify**: Scales map (clamped 0.75-1.5x)

---

## 4. Coordinate System

### 4.1 Coordinate Flow
1. **Geographic**: Latitude/Longitude from Natural Earth
2. **Normalized**: (0,0) = NW corner, (1,1) = SE corner
3. **Local**: Centered at (0,0), scaled by map dimensions
4. **World**: Positioned relative to world anchor

### 4.2 Key Transformation
```swift
// No Y-axis inversion needed!
let localX = (x_norm - 0.5) * mapWidth  // Centers X
let localZ = (y_norm - 0.5) * mapHeight // Centers Z
```

---

## 5. Troubleshooting & Solutions

### 5.1 Bars Lying Flat
**Problem**: Bars appeared horizontal instead of vertical
**Solution**: 
- Changed bar parent from rotated MapPlane to MapRig
- Used small cube mesh scaled up instead of tall box mesh
- Fixed animation to preserve transform

### 5.2 Bar Misalignment
**Problem**: Bars appeared in wrong locations (ocean, etc.)
**Initial Theory**: Coordinate system mismatch
**Root Cause**: Y-coordinate was being inverted unnecessarily
**Solution**: Changed `(0.5 - y_norm)` to `(y_norm - 0.5)`

### 5.3 Missing Countries
**Problem**: FRA, NOR, REU not in Natural Earth data
**Solution**: Manually added with appropriate coordinates

### 5.4 Xcode Build Errors
**Problem**: Duplicate centroids.csv files
**Solution**: Removed duplicate from WorkingFiles/RawData/

---

## 6. File Structure

```
Data_Viz_Demo1/
├── Data_Viz_Demo1/
│   ├── DataFiles/              # Final data files
│   │   ├── bins.csv
│   │   ├── centroids.json
│   │   ├── countries.csv
│   │   └── year_*.csv
│   ├── Assets.xcassets/        # Map texture
│   │   └── world_equirect.imageset/
│   ├── WorkingFiles/           # Development files
│   │   ├── Scripts/            # Python processing scripts
│   │   └── RawData/            # Source data
│   └── Swift Files/
│       ├── Data_Viz_Demo1App.swift
│       ├── ContentView.swift
│       ├── ImmersiveView.swift
│       ├── MapScene.swift
│       ├── DataLoader.swift
│       ├── ControlPanel.swift
│       └── AppModel.swift
└── Packages/
    └── RealityKitContent/      # 3D assets
```

---

## 7. Technical Details

### 7.1 Data Format Specifications

#### bins.csv
```csv
Bin,Height,Color
0,0.01,#E8E8E8    # No cases
1,0.02,#FFE4B5    # 1 case
...
```

#### centroids.json
```json
{
  "USA": [0.229, 0.280],  // [x_norm, y_norm]
  "GBR": [0.494, 0.198],
  ...
}
```

#### year_YYYY.csv
```csv
Code,Bin
NGA,7
IND,6
...
```

### 7.2 Performance Optimizations
- Single shared mesh for all bars
- Batch loading of data
- Efficient year switching with animations
- Gesture debouncing

### 7.3 Visual Design
- Color gradient from light (few cases) to dark red (many cases)
- Bar height proportional to case count (logarithmic bins)
- Smooth animations for year transitions
- Clean, borderless map for focus on data

---

## Key Learnings Summary

1. **Use Natural Earth label points**, not geometric centroids
2. **RealityKit plane rotation** doesn't require coordinate inversion
3. **Entity hierarchy matters** - bars must not inherit map rotation
4. **Debug visually** with markers at known positions
5. **Equirectangular projection** maps directly to normalized coordinates
6. **Test with reference data** (Our World in Data) to verify accuracy

---

## Running the Project

1. Ensure Xcode 15.2+ with visionOS SDK
2. Open `Data_Viz_Demo1.xcodeproj`
3. Select visionOS Simulator or connected Apple Vision Pro
4. Build and run
5. Click "Show Immersive Space" to enter visualization
6. Use year selector to switch between 2000-2002
7. Interact with gestures to explore the data

---

*Last Updated: [Current Date]*
*Documentation covers the complete pipeline from raw Natural Earth data to functioning visionOS app*
