# Polio Data Visualization - Project Overview

## What This Is
An Apple Vision Pro app that visualizes the global fight against polio from 1980-2023 using 3D bars on an immersive world map.

## Key Documentation

### For Users
- [App README](Data_Viz_Demo1/README.md) - Features and overview

### For Developers  
- [Data Management Guide](DATA_MANAGEMENT_GUIDE.md) - **How to update data**
- [Data Processing Pipeline](DATA_PROCESSING_PIPELINE.md) - Quick reference for processing steps
- [Coordinate System Notes](Data_Viz_Demo1/COORDINATE_SYSTEM_NOTES.md) - RealityKit coordinate learnings



## Quick Stats
- **Years**: 1980-2023 (44 years)
- **Countries**: 201
- **Data Source**: Our World in Data (estimated paralytic polio cases)
- **Reduction**: 99.4% (736,820 cases in 1980 → 4,353 in 2023)

## Repository Structure
```
Data_Viz_Demo1/
├── Data_Viz_Demo1/          # Xcode project files
│   ├── *.swift              # App source code
│   ├── DataFiles/           # Processed data (bins, countries, years)
│   ├── Assets.xcassets/     # Map texture
│   └── WorkingFiles/        # Raw data and processing scripts
├── DATA_MANAGEMENT_GUIDE.md # How to update data
└── [Other documentation]
```

## Key Technologies
- visionOS 2.0+
- SwiftUI & RealityKit
- Python (data processing)
- Natural Earth (map data)
