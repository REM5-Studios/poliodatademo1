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
            VStack(spacing: 12) {
                Text("Polio Data Visualization")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Explore global polio cases from 1980 to 2023")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 40)
            
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
                    .frame(width: 750 * 1.1, height: 350) // Much wider chart area
                    
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
        .frame(width: 750, height: appModel.immersiveSpaceState == .open ? 600 : 500)
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
    
    // Get current year data for display
    private var currentYearData: GlobalTotals? {
        globalTotals.first { $0.year == currentYear }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Global Polio Cases & Immunization (1980-2023)")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Two separate charts side by side - wider spacing
            HStack(spacing: 40) {
                // Cases chart (left)
                VStack(spacing: 8) {
                    Text("Polio Cases")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    Chart(globalTotals) { data in
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
                        }
                        
                        // Add point annotation for current year
                        if data.year == currentYear {
                            PointMark(
                                x: .value("Year", data.year),
                                y: .value("Cases", data.estimatedCases)
                            )
                            .foregroundStyle(.red)
                            .symbolSize(60)
                            .annotation(position: .trailing) {
                                Text("\(Int(data.estimatedCases).formatted(.number.notation(.compactName)))")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.red.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .chartYScale(domain: 0...400000)
                    .chartXScale(domain: 1980...2023)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 10)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let year = value.as(Int.self) {
                                    Text("\(year)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let cases = value.as(Double.self) {
                                    if cases >= 1000 {
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
                    .frame(height: 220)
                }
                .frame(maxWidth: .infinity) // Take up more space
                
                // Immunization chart (right)
                VStack(spacing: 8) {
                    Text("Immunization Rate")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    
                    Chart(globalTotals) { data in
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
                        }
                        
                        // Add point annotation for current year
                        if data.year == currentYear {
                            PointMark(
                                x: .value("Year", data.year),
                                y: .value("Rate", data.immunizationRate)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(60)
                            .annotation(position: .trailing) {
                                Text("\(Int(data.immunizationRate))%")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .chartXScale(domain: 1980...2023)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 10)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let year = value.as(Int.self) {
                                    Text("\(year)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
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
                    .frame(height: 220)
                }
                .frame(maxWidth: .infinity) // Take up more space
            }
            .padding(.horizontal, 16)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}

extension Notification.Name {
    static let yearChanged = Notification.Name("yearChanged")
    static let resetMapPosition = Notification.Name("resetMapPosition")
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
