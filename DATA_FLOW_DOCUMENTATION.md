# Data Flow Documentation - Polio Visualization App

## Overview

This document describes the complete data flow from Our World in Data (OWID) to the final visualization in the Apple Vision Pro app. The data pipeline transforms raw polio case data into binned, normalized visualization data while preserving actual case counts for display.

## Data Sources

### Primary Data Source
- **File**: `number-of-estimated-paralytic-polio-cases-by-world-region.csv`
- **Source**: Our World in Data
- **Coverage**: 1980-2023
- **Content**: Estimated paralytic polio cases by country and region
- **Format**: Entity, Code, Year, Estimated polio cases

### Supporting Data Files
1. **Natural Earth Data** (for country positions):
   - `ne_10m_admin_0_countries.shp` - Country boundary shapefile
   - `ne_admin0_label_points.csv` - Extracted label points

2. **Timeline Data**:
   - `polio_timeline.csv` - Historical events and milestones
   - `polio_timeline_categories.csv` - Categorized timeline events

3. **Global Totals**:
   - `Global_Polio_Totals_Simplified__1980_2023_.csv` - Aggregated global statistics including immunization rates

## Data Processing Pipeline

### 1. Raw Data → Year Files

**Script**: `process_complete_polio_dataset.py`

**Process**:
1. Loads raw OWID data from `number-of-estimated-paralytic-polio-cases-by-world-region.csv`
2. Filters out regional aggregates (Africa, Asia, etc.) and OWID codes
3. Applies bin categorization based on case counts
4. Creates individual year files (year_1980.csv through year_2023.csv)

**Output Format**:
```csv
Code,Bin
AFG,1
PAK,2
```

### 2. Case Count Preservation

**Script**: `create_case_counts_lookup.py`

**Purpose**: Preserves actual case numbers for popup displays while using bins for visualization heights

**Process**:
1. Loads raw case data from multiple sources
2. Creates JSON lookup: `case_counts.json`
3. Structure: year → country → cases

### 3. Country Position Data

**Scripts**:
1. `extract_label_points_from_shapefile.py` - Extracts geographic coordinates
2. `make_centroids_from_natural_earth.py` - Normalizes to equirectangular projection
3. `add_missing_countries_to_centroids.py` - Adds missing countries (FRA, NOR, REU)

**Output**: `centroids.json` with normalized x,y coordinates (0-1 range)

### 4. Regional Data Processing

**Script**: `prepare_regional_data.py`

**Process**:
1. Extracts regional aggregates from raw data
2. Merges with immunization rates from global totals
3. Creates `regional_polio_data.csv` for charts

### 5. Timeline Processing

**Script**: `convert_timeline_categories_to_json.py`

**Process**:
1. Converts CSV timeline data to JSON
2. Maps years to events with categories, headlines, and subtext
3. Output: `polio_timeline_categories.json`

## Data Flow in the App

### Loading Sequence

1. **App Launch**:
   ```
   DataLoader.loadStaticData() → Loads:
   - bins.csv (height/color mapping)
   - countries.csv (country names)
   - centroids.json (positions)
   - case_counts.json (actual values)
   - regional_polio_data.csv (charts)
   - polio_timeline_categories.json (info panels)
   ```

2. **Year Selection**:
   ```
   DataLoader.loadYear(year) → Loads:
   - year_YYYY.csv (country bins for that year)
   - Uses cached case_counts for actual values
   ```

### Data Usage

1. **3D Bars**:
   - Position: From `centroids.json`
   - Height: From bin level in `year_YYYY.csv` → `bins.csv`
   - Color: From bin level → `bins.csv`
   - Popup value: From `case_counts.json`

2. **Charts**:
   - Global data: From `GlobalTotals` in DataLoader
   - Regional data: From `regional_polio_data.csv`

3. **Info Panel**:
   - Timeline events: From `polio_timeline_categories.json`
   - Statistics: Calculated from current year data

## Bin System

Current bins (defined in `bins.csv`):

| Bin | Case Range | Height | Color |
|-----|------------|--------|--------|
| 0 | 0 | 0mm | Transparent |
| 1 | 1 | 25mm | Light yellow |
| 2 | 2-5 | 50mm | Yellow |
| 3 | 6-15 | 75mm | Light orange |
| 4 | 16-40 | 100mm | Orange |
| 5 | 41-100 | 125mm | Dark orange |
| 6 | 101-300 | 150mm | Deep orange |
| 7 | 301-1,000 | 175mm | Red-orange |
| 8 | 1,001-3,000 | 200mm | Dark red-orange |
| 9 | 3,001-10,000 | 225mm | Dark red |
| 10 | 10,001-270,000 | 250mm | Darkest red |

## Update Process

To update with new data:

1. Download new data from OWID
2. Place in `WorkingFiles/RawData/`
3. Run `process_complete_polio_dataset.py`
4. Run `create_case_counts_lookup.py` (if needed)
5. Run `prepare_regional_data.py` (if updating regional data)
6. Test in app

## File Dependencies

### Required for App Operation
- `DataFiles/bins.csv` - Bar heights and colors
- `DataFiles/countries.csv` - Country list
- `DataFiles/centroids.json` - Country positions
- `DataFiles/year_*.csv` - Annual case data (44 files)
- `DataFiles/case_counts.json` - Actual case numbers
- `DataFiles/polio_timeline_categories.json` - Timeline events
- `Assets.xcassets/world_equirect.png` - Map texture

### Optional Enhancement Files
- `DataFiles/regional_polio_data.csv` - Regional chart data
- `WorkingFiles/RawData/Global_Polio_Totals_Simplified__1980_2023_.csv` - Global statistics

## Notes

- The app uses a two-tier data system: bins for visualization, actual counts for display
- Country codes must match between all data files (ISO-3 format)
- Regional aggregates are filtered out during processing
- The coordinate system uses normalized equirectangular projection (0-1 range)
