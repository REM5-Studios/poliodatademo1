# Guide: Extending Polio Visualization to 2023

## Overview
Current implementation covers 2000-2002. To extend to 2023, we need data for 21 additional years.

## Steps Required

### 1. Data Acquisition
**Source**: Our World in Data (https://ourworldindata.org/polio)
- Download complete polio dataset (1980-2023)
- Ensure data includes both wild poliovirus and vaccine-derived cases
- Verify country codes match our ISO-3 format

### 2. Data Processing

#### 2.1 Create Year Files
For each year 2003-2023, create `year_YYYY.csv`:
```csv
Code,Bin
NGA,5
PAK,7
AFG,6
...
```

#### 2.2 Update Bins if Needed
Check if current bins (0-10) adequately cover all years:
- Recent years have fewer cases (mostly Pakistan/Afghanistan)
- May need to adjust bin thresholds for better granularity
- Current max bin (58,067 cases) likely sufficient

### 3. Code Updates

#### 3.1 Update Year Range in Swift
```swift
// ControlPanel.swift
let years = Array(2000...2023)  // Instead of [2000, 2001, 2002]

// ContentView.swift
@State private var currentYear = 2000  // Or 2023 to start with recent
```

#### 3.2 File Management Considerations
```swift
// DataLoader.swift - No changes needed!
// Already uses dynamic loading: loadYear(_ year: Int)
```

### 4. UI/UX Adjustments

#### 4.1 Year Selector UI Options
1. **Scrollable buttons** (current approach won't scale well)
2. **Slider** for continuous year selection
3. **Segmented decades** + year picker
4. **Play button** for animation through years

Example slider approach:
```swift
VStack {
    Slider(value: $currentYear, in: 2000...2023, step: 1)
    Text("Year: \(Int(currentYear))")
}
```

### 5. Performance Optimizations

#### 5.1 Memory Management
- 24 years × ~50 countries with data = ~1,200 data points
- Current approach loads one year at a time ✅
- No memory issues expected

#### 5.2 Preloading Strategy
```swift
// Optional: Preload adjacent years for smoother transitions
private func preloadAdjacentYears(_ year: Int) async {
    let yearsToLoad = [year - 1, year, year + 1].filter { $0 >= 2000 && $0 <= 2023 }
    // Load in background
}
```

## Risks and Mitigations

### 1. ⚠️ **Data Consistency Risk**
**Issue**: Country codes or data format might change over 24 years
**Mitigation**: 
- Run integrity check on all years
- Create validation script to ensure all years follow same format
- Handle missing countries gracefully

### 2. ⚠️ **UI Scalability Risk**
**Issue**: 24 buttons won't fit nicely
**Mitigation**: 
- Implement slider or dropdown
- Group by decades
- Add keyboard shortcuts for year navigation

### 3. ⚠️ **Visual Clarity Risk**
**Issue**: Recent years have very few cases (only 2-3 countries)
**Mitigation**:
- Adjust bin thresholds for recent years
- Add visual emphasis for the few remaining endemic countries
- Consider different visualization for near-eradication years

### 4. ⚠️ **Missing Data Risk**
**Issue**: Some years might have gaps or reporting delays
**Mitigation**:
- Clearly indicate "No data" vs "Zero cases"
- Add data source year to UI
- Document any data limitations

### 5. ⚠️ **Performance Risk**
**Issue**: Rapid year switching might cause lag
**Mitigation**:
- Current animation duration is good
- Consider caching recently viewed years
- Add loading indicator if needed

## Implementation Order

1. **Download and process data** (2003-2023)
2. **Run integrity checks** on all new files
3. **Test with a few years** (e.g., 2003, 2010, 2020)
4. **Update UI** to handle year selection
5. **Optimize** based on performance testing
6. **Add polish** (play button, speed controls, etc.)

## Data Processing Script Example

```python
# process_polio_data_2003_2023.py
import pandas as pd
import csv

# Load OWID data
df = pd.read_csv('owid-polio-data.csv')

# For each year
for year in range(2003, 2024):
    year_data = df[df['year'] == year]
    
    # Filter for countries with cases
    positive_cases = year_data[year_data['cases'] > 0]
    
    # Map to bins
    output = []
    for _, row in positive_cases.iterrows():
        iso3 = row['iso_code']
        cases = row['cases']
        bin_num = calculate_bin(cases)  # Use existing bin logic
        output.append({'Code': iso3, 'Bin': bin_num})
    
    # Save year file
    with open(f'year_{year}.csv', 'w') as f:
        writer = csv.DictWriter(f, fieldnames=['Code', 'Bin'])
        writer.writeheader()
        writer.writerows(output)
```

## Visual Storytelling Opportunities

With 24 years of data, you could show:
1. **The decline**: From widespread (2000) to near-eradication (2023)
2. **Last endemic countries**: Pakistan and Afghanistan's persistence
3. **Outbreaks**: Temporary resurgences in previously polio-free areas
4. **Success stories**: India's elimination, Africa's certification

## Conclusion

The framework is well-designed for extension:
- ✅ Data structure supports any year
- ✅ Dynamic loading prevents memory issues
- ✅ Visualization scales appropriately
- ⚠️ Main challenge: UI for year selection
- ⚠️ Secondary challenge: Data validation across 24 years

Estimated effort: 2-4 hours for basic extension, 4-8 hours with UI improvements and polish.
