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
            Text("Global Polio Data")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
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
                GlobalTotalsChart(
                    currentYear: $currentYear,
                    globalTotals: DataLoader.shared.globalTotals
                )
                .frame(width: 1100, height: 560) // Adjusted to fit new chart dimensions
                
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
            
            // Citation footnote
            Text("Data: WHO & UNICEF (2025), UN World Population Prospects (2024), WHO (2019, 2024) – processed by Our World in Data")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .frame(width: appModel.immersiveSpaceState == .open ? 1200 : 750, height: appModel.immersiveSpaceState == .open ? 700 : 530)
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
                    .offset(x: 10)  // Spread apart from main window
                    .offset(y: -5)  // Match left panel vertical alignment
                    .offset(z: 150)  // Closer to user than left panel
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
                    .offset(x: -10)  // Spread apart from main window
                    .offset(y: -5)  // Slight upward adjustment to align with chart
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
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        // Use the new dynamic chart that responds to country/region/world selections
        CasesVsImmunizationChart()
            .frame(height: 640)
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
