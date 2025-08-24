# Polio Data Visualization for visionOS

An immersive 3D visualization for Apple Vision Pro showing global reported paralytic polio cases (2000-2002) with 3D bars rising from country locations on a world map.

## Features

- **Immersive 3D Experience**: Tabletop visualization at comfortable viewing height
- **Interactive Controls**: Drag to move, rotate, and pinch to zoom the map
- **Animated Transitions**: Smooth animations when switching between years
- **Data-Driven Colors**: Visual gradient from light (few cases) to dark red (many cases)

## Project Structure

```
Data_Viz_Demo1/
├── DataFiles/             # Production data (bundled with app)
│   ├── bins.csv          # Height/color mapping for 11 levels
│   ├── countries.csv     # 199 ISO3 country codes
│   ├── centroids.json    # Normalized country positions
│   └── year_*.csv        # Case data by year
│
├── Assets.xcassets/      # Map texture
│   └── world_equirect.imageset/
│
├── WorkingFiles/         # Development files (not bundled)
│   ├── Scripts/          # Python data processing scripts
│   └── RawData/          # Source Natural Earth data
│
└── Swift Files:
    ├── Data_Viz_Demo1App.swift  # App entry point
    ├── ContentView.swift         # 2D window UI
    ├── ImmersiveView.swift       # Immersive space wrapper
    ├── MapScene.swift            # Main 3D visualization
    ├── DataLoader.swift          # Data loading logic
    ├── ControlPanel.swift        # Year selector UI
    └── AppModel.swift            # App state management
```

## Technical Details

- **Platform**: visionOS 2.5+ (Apple Vision Pro exclusive)
- **Frameworks**: SwiftUI, RealityKit
- **Data Source**: Natural Earth shapefiles + WHO polio data
- **Map Projection**: Equirectangular (4096×2048)

## Documentation

- **[PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)**: Complete development guide
- **[DATA_PROCESSING_PIPELINE.md](DATA_PROCESSING_PIPELINE.md)**: Data regeneration steps
- **[COORDINATE_SYSTEM_NOTES.md](COORDINATE_SYSTEM_NOTES.md)**: Coordinate system details

## Quick Start

1. Open `Data_Viz_Demo1.xcodeproj` in Xcode 15.2+
2. Select visionOS Simulator or device
3. Build and run
4. Click "Show Immersive Space"
5. Use year buttons to explore 2000-2002 data

## Key Visualizations

- **2000**: Significant polio presence in Africa and South Asia
- **2001**: Reduction in cases, concentrated in fewer countries  
- **2002**: Further reduction, endemic areas becoming apparent

## Credits

- **Data**: World Health Organization (via Our World in Data)
- **Maps**: Natural Earth (public domain)
- **Development**: Built for Apple Vision Pro spatial computing
