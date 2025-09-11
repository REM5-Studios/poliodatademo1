# Preserved Knowledge from Deprecated Scripts

This document preserves important information from scripts that are being deprecated in favor of `process_complete_polio_dataset.py`.

## Important Data Source URLs

From `process_polio_1980_1999.py`:

### Our World in Data URLs
```python
# Primary URL for OWID polio data
OWID_POLIO_URL = "https://github.com/owid/owid-datasets/raw/master/datasets/Reported%20paralytic%20polio%20cases%20and%20deaths%20(WHO%202017)/Reported%20paralytic%20polio%20cases%20and%20deaths%20(WHO%202017).csv"

# Alternative URL if primary doesn't work
OWID_POLIO_ALT_URL = "https://raw.githubusercontent.com/owid/owid-datasets/master/datasets/Polio%20cases%20and%20deaths/Polio%20cases%20and%20deaths.csv"
```

### Download Function Pattern
The deprecated scripts show how to download data directly from OWID:
```python
def download_owid_data():
    """Download polio data from Our World in Data"""
    try:
        response = requests.get(OWID_POLIO_URL)
        response.raise_for_status()
        return response.text
    except:
        # Try alternative URL
        response = requests.get(OWID_POLIO_ALT_URL)
        response.raise_for_status()
        return response.text
```

## Data Format Variations

### Different Column Names
The scripts reveal that OWID data has used different column names over time:
- `Total polio cases` (in owid_polio_cases.csv)
- `Estimated polio cases` (in current data)
- Year data in columns (e.g., "1980", "1981" as column headers in some formats)

### Bin Column Name Variations
- `EdgeMax` vs `edge_max` in bins.csv
- `Level` vs `bin` for bin numbers

## Historical Context from process_polio_2008_2023.py

### Key Polio Events (2008-2023)
- **2008-2011**: Major outbreaks in Central Asia (Tajikistan had 458 cases in 2010)
- **2012-2015**: Syria outbreak due to conflict
- **2016-2019**: Contained mostly to Pakistan & Afghanistan
- **2020-2023**: Near eradication - only PAK & AFG remain endemic
- **2022**: USA had 1 vaccine-derived case

### Countries with Late-Stage Cases
The script contains hardcoded data showing which countries had cases in the final years:
- Persistent endemic: Pakistan (PAK), Afghanistan (AFG)
- Late outbreaks: Nigeria (NGA), Chad (TCD), Somalia (SOM)
- Vaccine-derived cases: Madagascar (MDG), Laos (LAO), Philippines (PHL)

## Data Processing Patterns

### Handling Missing Data
```python
# Remove rows with no data or zero cases
year_data = year_data[year_data['Value'].notna()]
year_data = year_data[year_data['Value'] > 0]
```

### Different Output Formats
The scripts show evolution of output formats:
1. **2-column format** (current): Code,Bin
2. **4-column format** (2000-2002): Code,Entity,Value,Bin

## File Naming Conventions

### Raw Data File Names
- `owid_polio_raw.csv` - Downloaded data
- `owid_polio_cases.csv` - OWID format
- `polio_wide_values_2000_2002.csv` - Wide format with actual values
- `polio_wide_bins_2000_2002.csv` - Wide format with bins

## Validation Patterns

### Country Code Validation
```python
# Load valid countries
with open('countries.csv', 'r') as f:
    reader = csv.DictReader(f)
    valid_countries = {row['Code'] for row in reader}

# Check validity
if code not in valid_countries:
    print(f"Warning: {code} not in valid countries list")
```

## Important Notes

1. **Data Source Evolution**: OWID has changed their data format and URLs over time. Always verify current format.

2. **Backup Creation**: The current process creates backups before overwriting data - this pattern should be maintained.

3. **Regional Filtering**: Always filter out regional aggregates (rows without country codes) when processing country-level data.

4. **Case Count Preservation**: The separate case_counts.json file is crucial for showing actual numbers in popups while using bins for visualization.

5. **Year Range Flexibility**: Scripts show different year ranges were processed separately, but the current unified approach is better.

## URLs to Monitor

If data updates fail, check these locations:
1. Our World in Data main site: https://ourworldindata.org/
2. OWID GitHub datasets: https://github.com/owid/owid-datasets
3. WHO polio data: Referenced but URL not provided in scripts

This knowledge should be referenced when troubleshooting data updates or if the current data source becomes unavailable.
