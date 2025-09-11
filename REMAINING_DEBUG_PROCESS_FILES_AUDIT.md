# Remaining Debug/Process Files Audit

## Debug/Test Files Still Present

### Debug Images (Can Remove)
These were supposed to be deleted but still exist:
- ❌ `WorkingFiles/bar_alignment_check.png` - Debug visualization
- ❌ `WorkingFiles/centroid_alignment_check.png` - Debug visualization
- ❌ `WorkingFiles/debug_map_coordinates.png` - Debug visualization
- ❌ `WorkingFiles/world_equirect_preview_simple.png` - Unused preview

### Potentially Redundant Scripts

1. **`convert_timeline_to_json.py`** 
   - Creates `polio_timeline.json`
   - But app uses `polio_timeline_categories.json`
   - Status: POSSIBLY UNUSED - need to verify

2. **`check_integrity.py`**
   - Generic integrity checker
   - Less useful than `check_integrity_csv.py`
   - Status: POSSIBLY REDUNDANT

### Backup/Old Files (Can Remove)
- ❌ `Data_Viz_Demo1.xcodeproj/project.pbxproj.backup` - Xcode project backup
- ❌ `Packages/.../WorldMap3Dold.usdz` - Old 3D map model
- ❌ `Packages/.../WorldMap3Dold2.usdz` - Another old 3D map model

### Empty Directory
- ❌ `WorkingFiles/UnusedTemplateFiles/` - Empty directory

## Scripts to KEEP (Still Needed)

### Active Data Processing
✅ **`process_complete_polio_dataset.py`** - Main data processor
✅ **`create_case_counts_lookup.py`** - Extracts actual case numbers
✅ **`prepare_regional_data.py`** - For regional charts
✅ **`convert_timeline_categories_to_json.py`** - Timeline data used by app

### Data Validation
✅ **`check_integrity_csv.py`** - Validates CSV data format (useful for updates)

## Data Files Analysis

### Timeline Data
- `polio_timeline.json` - Has different format (headline, stat, photo)
- `polio_timeline_categories.json` - Used by app (category, headline, subtext)
- The app ONLY uses the categories version

### Unused Raw Data?
Need to verify if these are still needed:
- `polio_long_2000_2002.csv`
- `polio_wide_bins_2000_2002.csv`
- Various other CSV files in RawData

## Recommendations

### Definitely Remove
1. All PNG files in WorkingFiles
2. Xcode project backup
3. Old USDZ files
4. Empty UnusedTemplateFiles directory
5. `convert_timeline_to_json.py` (creates unused output)

### Keep for Now
1. `check_integrity_csv.py` - Useful for data validation
2. Raw CSV files that might contain unique data

### Consider Removing After Testing
1. `check_integrity.py` - Generic version, less useful
2. Test-related files if not actively used

## Space Impact
- PNG files: ~1-2MB
- Old USDZ files: Potentially several MB each
- Scripts: Minimal space but reduce clutter
