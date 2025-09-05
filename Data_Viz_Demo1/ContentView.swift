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
            }
        }
    }
}

// MARK: - Global Totals Chart View

struct GlobalTotalsChart: View {
    @Binding var currentYear: Int
    let globalTotals: [GlobalTotals]
    @State private var selectedRegion = "World"
    
    let regions = ["World", "Africa", "Asia", "Europe", "North America", "Oceania", "South America"]
    
    // Get the appropriate data based on selected region
    private var displayData: [GlobalTotals] {
        if selectedRegion == "World" {
            return globalTotals
        } else {
            return DataLoader.shared.getRegionalData(for: selectedRegion)
        }
    }
    
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Region")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(regions, id: \.self) { region in
                        Button(action: {
                            selectedRegion = region
                        }) {
                            HStack {
                                Image(systemName: selectedRegion == region ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedRegion == region ? .blue : .secondary)
                                    .font(.system(size: 16))
                                
                                Text(region)
                                    .font(.subheadline)
                                    .foregroundStyle(selectedRegion == region ? .primary : .secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(selectedRegion == region ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .frame(width: 150)
            .padding()
            .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            
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
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            
                            PointMark(
                                x: .value("Year", data.year),
                                y: .value("Cases", data.estimatedCases)
                            )
                            .foregroundStyle(.red)
                            .symbolSize(80)
                            .annotation(position: .topTrailing) {
                                Text("\(Int(data.estimatedCases).formatted(.number.notation(.compactName)))")
                                    .font(.system(size: 15)) // Increased from ~12 to 15 (25% increase)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.red.opacity(0.2))
                                    .cornerRadius(4)
                                    .offset(x: 10, y: -5) // Move right and up
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
                                    } else if cases < 1000 {
                                        Text("\(Int(cases))")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                    } else {
                                        Text("\(Int(cases/1000))K")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                    }
                    .chartXAxis(.hidden) // Hide X-axis for top chart
                    .frame(height: 140)
                }
                
                // Visual separator
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.vertical, 8)
                
                // Immunization Rate Chart (bottom)
                VStack(spacing: 4) {
                    HStack {
                        Text("Immunization % (Global)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                    
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
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            
                            PointMark(
                                x: .value("Year", data.year),
                                y: .value("Rate", data.immunizationRate)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(80)
                            .annotation(position: .topTrailing) {
                                Text("\(Int(data.immunizationRate))%")
                                    .font(.system(size: 15)) // Increased from ~12 to 15 (25% increase)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.2))
                                    .cornerRadius(4)
                                    .offset(x: 10, y: -5) // Move right and up
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
                            AxisGridLine()
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
                }
                }
                .padding(.horizontal, 16)
                
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
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
