//
//  ContentView.swift
//  Data_Viz_Demo1
//
//  Created by amir berenjian on 8/23/25.
//

import SwiftUI
import RealityKit
import Charts

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @State private var currentYear = 1980
    @State private var isDataLoaded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 8) {
                Text("Global Polio Data")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("1980-2023")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Main content
            if appModel.immersiveSpaceState == .closed {
                // Show immersive space button
                VStack(spacing: 24) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                        .symbolEffect(.pulse)
                    
                    ToggleImmersiveSpaceButton()
                        .controlSize(.extraLarge)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 40)
                .frame(maxHeight: .infinity)
                
            } else {
                // Show global totals chart during immersive mode
                VStack {
                    Spacer()
                    
                    GlobalTotalsChart(
                        currentYear: $currentYear,
                        globalTotals: DataLoader.shared.globalTotals
                    )
                    .frame(width: 1050, height: 400) // Increased to accommodate region selector
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                
                // Reset map position button (center) - HIDDEN
                // HStack {
                //     Spacer()
                //     
                //     Button(action: {
                //         NotificationCenter.default.post(
                //             name: .resetMapPosition,
                //             object: nil
                //         )
                //     }) {
                //         Label("Reset Map Position", systemImage: "arrow.counterclockwise")
                //             .font(.callout)
                //     }
                //     .buttonStyle(.bordered)
                //     .controlSize(.regular)
                //     .padding(.bottom, 10)
                //     
                //     Spacer()
                // }
            }
            
            Spacer()
        }
        .frame(width: appModel.immersiveSpaceState == .open ? 1150 : 750, height: appModel.immersiveSpaceState == .open ? 650 : 500)
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                currentYear = year
            }
        }
        .ornament(
            attachmentAnchor: .scene(.trailing),
            contentAlignment: .center
        ) {
            if appModel.immersiveSpaceState == .open {
                DataOrnamentsView()
                    .rotation3DEffect(
                        .degrees(-33),  // Angle away from user to complement left panel
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(z: 130)  // Closer to user than before
            }
        }
        .ornament(
            attachmentAnchor: .scene(.leading),
            contentAlignment: .center
        ) {
            if appModel.immersiveSpaceState == .open {
                YearInfoPanel(currentYear: $currentYear)
                    .rotation3DEffect(
                        .degrees(33),  // Angle toward user
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(y: 0)  // Center vertically
                    .offset(z: 200)  // Matched depth with right panels
            }
        }
        .task {
            // Pre-load static data when the app starts
            // This ensures timeline data is ready before the immersive space opens
            do {
                try await DataLoader.shared.loadStaticData()
                isDataLoaded = true
            } catch {
                print("ContentView: Failed to load static data: \(error)")
            }
        }
    }
}

// MARK: - Region Selector View

struct RegionSelector: View {
    @Binding var selectedRegion: String
    let regions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Region")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(regions, id: \.self) { region in
                    Button(action: {
                        selectedRegion = region
                    }) {
                        Text(region)
                            .font(.subheadline)
                            .foregroundStyle(selectedRegion == region ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedRegion == region ? Color.blue : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.blue, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .frame(width: 180)
        .padding()
        .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Cases Chart View

struct CasesChart: View {
    let displayData: [GlobalTotals]
    let currentYear: Int
    let maxCases: Double
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Cases")
                    .font(.caption)
                    .foregroundStyle(.red)
                Spacer()
            }
            
            Chart(displayData) { data in
                LineMark(
                    x: .value("Year", data.year),
                    y: .value("Cases", data.estimatedCases)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                if data.year == currentYear {
                    RuleMark(x: .value("Current Year", data.year))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Year", data.year),
                        y: .value("Cases", data.estimatedCases)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(80)
                    .annotation(position: .topTrailing) {
                        Text("\(Int(data.estimatedCases).formatted(.number.notation(.compactName)))")
                            .font(.system(size: 15))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.2))
                            .cornerRadius(4)
                            .offset(x: 10, y: -5)
                    }
                }
            }
            .chartYScale(domain: 0...maxCases)
            .chartXScale(domain: 1980...2023)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let cases = value.as(Double.self) {
                            if cases == 0 {
                                Text("0")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            } else if cases >= 1000 {
                                Text("\(Int(cases/1000))K")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            } else {
                                Text("\(Int(cases))")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { _ in
                    AxisGridLine()
                }
            }
            .frame(height: 140)
        }
    }
}

// MARK: - Immunization Chart View

struct ImmunizationChart: View {
    let displayData: [GlobalTotals]
    let currentYear: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Chart(displayData) { data in
                LineMark(
                    x: .value("Year", data.year),
                    y: .value("Rate", data.immunizationRate)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                if data.year == currentYear {
                    RuleMark(x: .value("Current Year", data.year))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Year", data.year),
                        y: .value("Rate", data.immunizationRate)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(80)
                    .annotation(position: .topTrailing) {
                        Text("\(Int(data.immunizationRate))%")
                            .font(.system(size: 15))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(4)
                            .offset(x: 10, y: -5)
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartXScale(domain: 1980...2023)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 20, 40, 60, 80, 100]) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let rate = value.as(Double.self) {
                            Text("\(Int(rate))%")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    AxisTick()
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text(String(year))
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .frame(height: 140)
            
            HStack {
                Text("Immunization % (Global)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Global Totals Chart View

struct GlobalTotalsChart: View {
    @Binding var currentYear: Int
    let globalTotals: [GlobalTotals]
    @State private var selectedRegion = "World"
    @State private var displayData: [GlobalTotals] = []
    
    let regions = ["World", "Africa", "Asia", "Europe", "North America", "Oceania", "South America"]
    
    // Calculate maximum cases for dynamic Y-axis scaling
    private var maxCases: Double {
        let maxValue = displayData.map { $0.estimatedCases }.max() ?? 500000
        // Round up to nearest nice number for axis
        if maxValue < 1000 {
            return ceil(maxValue / 100) * 100
        } else if maxValue < 10000 {
            return ceil(maxValue / 1000) * 1000
        } else if maxValue < 100000 {
            return ceil(maxValue / 10000) * 10000
        } else {
            return ceil(maxValue / 100000) * 100000
        }
    }
    
    // Get current year data for display
    private var currentYearData: GlobalTotals? {
        displayData.first { $0.year == currentYear }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Region selector on the left
            RegionSelector(selectedRegion: $selectedRegion, regions: regions)
            
            // Charts on the right
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Cases vs. Immunization Rate")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                    
                    Text(selectedRegion)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                }
                
                // Stacked charts with shared X-axis
                VStack(spacing: 0) {
                    // Polio Cases Chart (top)
                    CasesChart(
                        displayData: displayData,
                        currentYear: currentYear,
                        maxCases: maxCases
                    )
                    
                    // Spacing between charts
                    Spacer()
                        .frame(height: 16)
                    
                    // Immunization Rate Chart (bottom)
                    ImmunizationChart(
                        displayData: displayData,
                        currentYear: currentYear
                    )
                }
                .padding(.horizontal, 16)
                
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            // Initialize with World data
            displayData = globalTotals
        }
        .onChange(of: selectedRegion) { _, newRegion in
            // Update data when region changes
            if newRegion == "World" {
                displayData = globalTotals
            } else {
                displayData = DataLoader.shared.getRegionalData(for: newRegion)
            }
        }
    }
}

extension Notification.Name {
    static let yearChanged = Notification.Name("yearChanged")
    static let resetMapPosition = Notification.Name("resetMapPosition")
    static let sliderUpdateForStory = Notification.Name("sliderUpdateForStory")
    static let storyModeStateChanged = Notification.Name("storyModeStateChanged")
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
