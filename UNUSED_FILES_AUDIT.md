# Unused Files Audit

This document lists files that appear to be unused or redundant in the current data pipeline.

## Unused Processing Scripts

These scripts appear to be older versions or alternative approaches that have been superseded by `process_complete_polio_dataset.py`:

### Redundant Processing Scripts
1. **`process_polio_1980_1999.py`** 
   - Purpose: Process data for years 1980-1999
   - Status: UNUSED - Superseded by `process_complete_polio_dataset.py`
   - Note: Attempts to download data directly from OWID

2. **`process_polio_2003_2023.py`**
   - Purpose: Process data for years 2003-2023
   - Status: UNUSED - Superseded by `process_complete_polio_dataset.py`

3. **`process_polio_2008_2023.py`**
   - Purpose: Process data for years 2008-2023
   - Status: UNUSED - Superseded by `process_complete_polio_dataset.py`

4. **`process_historical_polio.py`**
   - Purpose: Process historical data from local file
   - Status: UNUSED - Superseded by `process_complete_polio_dataset.py`

### Potentially Unused Data Files

1. **`owid_polio_cases.csv`**
   - Location: `WorkingFiles/RawData/`
   - Purpose: Alternative OWID data format
   - Status: UNUSED - Using `number-of-estimated-paralytic-polio-cases-by-world-region.csv` instead

2. **`polio_long_2000_2002.csv`**
   - Location: `WorkingFiles/RawData/`
   - Purpose: Long format data for 2000-2002
   - Status: UNCLEAR - May be historical reference

3. **`polio_wide_bins_2000_2002.csv`**
   - Location: `WorkingFiles/RawData/`
   - Purpose: Wide format bin data for 2000-2002
   - Status: UNCLEAR - May be historical reference

4. **`polio_wide_values_2000_2002.csv`**
   - Location: `WorkingFiles/RawData/`
   - Purpose: Wide format value data for 2000-2002
   - Status: POSSIBLY USED - Referenced in `create_case_counts_lookup.py` for precise values

5. **`ne_10m_geography_regions_points.shp`**
   - Location: `WorkingFiles/RawData/`
   - Purpose: Geographic regions shapefile
   - Status: UNUSED - Using country-level data instead

### Verification Scripts (Keep for Maintenance)

These scripts are useful for debugging and verification, recommend keeping:

1. **`check_integrity.py` / `check_integrity_csv.py`** - Data validation
2. **`verify_alignment.py`** - Visual alignment checking
3. **`check_bar_alignment.py`** - Bar position verification
4. **`debug_map_coordinates.py`** - Coordinate system debugging

### Template Files

1. **`UnusedTemplateFiles/`** directory
   - Contains Swift template files
   - Status: UNUSED - Can be removed

## Recommendations

### Files Safe to Remove
1. All redundant processing scripts (process_polio_*.py except process_complete_polio_dataset.py)
2. `owid_polio_cases.csv` (if confirmed unused)
3. `UnusedTemplateFiles/` directory
4. `ne_10m_geography_regions_points.shp`

### Files to Keep
1. All verification/debugging scripts
2. `polio_wide_values_2000_2002.csv` (used for precise case counts)
3. Natural Earth country shapefiles (needed for map generation)
4. All scripts in active pipeline (see DATA_FLOW_DOCUMENTATION.md)

### Before Removing
1. Create a backup of files to be removed
2. Verify app still functions correctly
3. Check if any scripts reference these files

## Important Note

Key knowledge from the deprecated scripts has been preserved in:
- [PRESERVED_KNOWLEDGE_FROM_DEPRECATED_SCRIPTS.md](PRESERVED_KNOWLEDGE_FROM_DEPRECATED_SCRIPTS.md)

This includes:
- Alternative OWID data URLs
- Historical context about polio decline
- Data format variations
- Validation patterns
