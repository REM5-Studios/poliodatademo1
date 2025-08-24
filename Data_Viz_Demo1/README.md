# Polio Data Visualization for Apple Vision Pro

An immersive 3D data visualization showing the global fight against polio from 1980 to 2023.

## Overview

This visionOS app presents polio case data as 3D bars rising from a world map, allowing users to see the dramatic reduction in cases over 44 years. Built exclusively for Apple Vision Pro using SwiftUI and RealityKit.

## Features

- **Immersive 3D Visualization**: Bars rise from country centroids on a floating world map
- **Time Navigation**: Slider to explore any year from 1980-2023
- **Gesture Controls**: Drag to rotate, pinch to scale, two-finger drag to move
- **Animated Transitions**: Smooth animations when changing years
- **Color-Coded Data**: Yellow (low) to dark red (high) representing case severity

## Data

- **Source**: Our World in Data (estimated paralytic polio cases)
- **Coverage**: 1980-2023, 201 countries
- **Notable Insights**:
  - 1980: 113 countries with 736,820 total cases
  - 2023: 25 countries with 4,353 total cases (99.4% reduction)
  - Only 2 endemic countries remain: Pakistan and Afghanistan

## Technical Stack

- **Platform**: visionOS 2.0+
- **Frameworks**: SwiftUI, RealityKit
- **Language**: Swift 5.9
- **Xcode**: 15.0+

## Project Structure

```
Data_Viz_Demo1/
├── ContentView.swift        # Main window UI
├── ControlPanel.swift       # Year selection slider
├── ImmersiveView.swift      # Container for 3D scene
├── MapScene.swift           # Core 3D visualization
├── DataLoader.swift         # CSV/JSON data loading
├── DataFiles/               # Processed data files
├── Assets.xcassets/         # Map texture and app icons
└── WorkingFiles/            # Data processing scripts
```

## Key Components

### MapScene
- Creates and manages the 3D scene
- Handles bar creation and animation
- Manages gesture interactions

### DataLoader
- Singleton pattern for data management
- Loads bins, countries, centroids, and year data
- Handles both 2-column and 4-column CSV formats

### Data Processing
- Python scripts in `WorkingFiles/Scripts/`
- Converts raw OWID data to app format
- Applies bin categorization for visual heights

## Installation

1. Open `Data_Viz_Demo1.xcodeproj` in Xcode
2. Select your development team
3. Build and run on Apple Vision Pro or simulator

## Data Updates

See [DATA_MANAGEMENT_GUIDE.md](../DATA_MANAGEMENT_GUIDE.md) for detailed instructions on updating the data.

## Credits

- Data: Our World in Data, WHO
- Map Data: Natural Earth
- Development: REM5 Studios

## License

[Add your license here]