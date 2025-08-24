# Data Management Guide

This guide documents how to update and manage data for the Polio Data Visualization app.

## Current Data Source

- **Dataset**: "Estimated paralytic polio cases" from Our World in Data
- **File**: `WorkingFiles/RawData/number-of-estimated-paralytic-polio-cases-by-world-region.csv`
- **Coverage**: 1980-2023
- **Type**: Estimated paralytic cases (includes both wild and vaccine-derived)
- **Countries**: 201 unique countries/territories
- **Excluded**: Regional aggregates (Africa, Asia, etc.) and OWID codes

## Data Processing Pipeline

### 1. Obtain New Data

Download from Our World in Data:
```bash
curl -L "https://ourworldindata.org/grapher/the-number-of-reported-paralytic-polio-cases.csv" -o new_data.csv
```

### 2. Process the Data

Use the processing script:
```bash
cd Data_Viz_Demo1/WorkingFiles/Scripts
python process_complete_polio_dataset.py
```

The script will:
- Filter out regional aggregates (Africa, Asia, etc.)
- Remove OWID codes (OWID_WRL, etc.)
- Apply bin categorization
- Create individual year files

### 3. Bin System

Current bins (in `DataFiles/bins.csv`):
| Bin | Range | Height | Color |
|-----|-------|--------|--------|
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

### 4. File Structure

```
DataFiles/
├── bins.csv          # Bin definitions
├── countries.csv     # Country names and codes
├── centroids.json    # Country positions
├── year_1980.csv     # Per-year data files
├── year_1981.csv
└── ... through year_2023.csv
```

## Adding New Years

1. Ensure new data is in the same format:
   ```csv
   Entity,Code,Year,Estimated polio cases
   Afghanistan,AFG,2024,5
   ```

2. Run the processing script - it will automatically create new year files

3. Update the UI slider range in `ControlPanel.swift`:
   ```swift
   Slider(value: $sliderValue, in: 1980...2024, step: 1)
   ```

## Updating Bin Thresholds

1. Edit `DataFiles/bins.csv`
2. Rerun `process_complete_polio_dataset.py` to reprocess all years
3. No code changes needed - the app reads bins dynamically

## Country Mapping

- Countries are matched by ISO-3 codes
- Centroids from Natural Earth data
- Missing countries are automatically excluded
- No manual country mapping needed

## Important Notes

1. **Data Consistency**: Always use "estimated cases" data for consistency
2. **Filtering**: Regional totals are automatically filtered out
3. **Backups**: The processing script creates backups automatically
4. **Testing**: Check a few key years after updates:
   - 1981: Should show India at maximum (bin 10)
   - 2023: Should show only Pakistan and Afghanistan

## Troubleshooting

### Missing Countries
- Check if country code exists in `countries.csv`
- Verify centroid exists in `centroids.json`

### Data Not Showing
- Ensure year file exists in `DataFiles/`
- Check console for "DataLoader" messages
- Verify file format matches expected 2-column format

### Xcode Build Issues
- Remove any backup folders from the project directory
- Check for duplicate files in project navigator
