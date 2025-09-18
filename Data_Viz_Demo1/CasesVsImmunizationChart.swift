//
//  CasesVsImmunizationChart.swift
//  Data_Viz_Demo1
//
//  Dynamic chart showing cases vs immunization for world/region/country
//

import SwiftUI
import Charts

struct CasesVsImmunizationChart: View {
    @Environment(AppModel.self) var appModel
    @State private var dataLoader = DataLoader.shared
    @State private var chartData: [GlobalTotals] = []
    @State private var currentYear = 1980
    
    // Calculate max cases for scaling
    private var maxCases: Double {
        chartData.map { $0.estimatedCases }.max() ?? 500000
    }
    
    // Scale cases to 0-100 range for chart
    private func scaledCases(_ cases: Double) -> Double {
        guard maxCases > 0 else { return 0 }
        return (cases / maxCases) * 100
    }
    
    // Get data for current year
    private var currentYearData: GlobalTotals? {
        chartData.first { $0.year == currentYear }
    }
    
    // Number formatter for clean display
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    // Calculate axis values for cases
    private var casesAxisValues: [Double] {
        [0, 25, 50, 75, 100]
    }
    
    // Format axis labels for cases
    private func casesAxisLabel(_ value: AxisValue) -> String {
        let scaledValue = value.as(Double.self) ?? 0
        let actualValue = (scaledValue / 100) * maxCases
        
        return numberFormatter.string(from: NSNumber(value: Int(actualValue))) ?? "0"
    }
    
    // Get data based on current view mode
    private func loadChartData() {
        switch appModel.chartViewMode {
        case .world:
            chartData = dataLoader.globalTotals
        case .region(let region):
            chartData = dataLoader.getRegionalData(for: region)
        case .country(let code, _):
            chartData = dataLoader.getCountryData(for: code)
        }
    }
    
    // Check if a region is currently selected
    private func isRegionSelected(_ regionDisplay: String) -> Bool {
        switch appModel.chartViewMode {
        case .world:
            return false
        case .region(let currentRegion):
            // Handle the abbreviated names
            if regionDisplay == "N. America" && currentRegion == "North America" {
                return true
            }
            if regionDisplay == "S. America" && currentRegion == "South America" {
                return true
            }
            return currentRegion == regionDisplay
        case .country:
            // When viewing a country, no region is highlighted
            return false
        }
    }
    
    // Get flag emoji for country code
    private func getFlagEmoji(for countryCode: String) -> String? {
        // For special codes or non-2-letter codes, return nil
        if countryCode.starts(with: "OWID_") || countryCode.count != 2 {
            return nil
        }
        
        // Convert ISO-2 code to flag emoji
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalar))
            }
        }
        return emoji.isEmpty ? nil : emoji
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with title and navigation
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Cases vs. Immunization Rate")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                // Navigation section - single row
                HStack(spacing: 10) {
                    // World button (double width)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appModel.chartViewMode = .world
                        }
                    }) {
                        Text("World")
                            .font(.system(size: 15, weight: .medium))
                            .frame(width: 90, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(appModel.chartViewMode == .world ? Color.blue : Color.white.opacity(0.1))
                            )
                            .foregroundStyle(appModel.chartViewMode == .world ? .white : .white.opacity(0.8))
                            .scaleEffect(appModel.chartViewMode == .world ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect()
                    
                    // Region buttons
                    ForEach(["Africa", "Asia", "Europe", "N. America", "S. America", "Oceania"], id: \.self) { region in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                let actualRegion = region == "N. America" ? "North America" : 
                                                  region == "S. America" ? "South America" : region
                                appModel.chartViewMode = .region(actualRegion)
                            }
                        }) {
                            Text(region)
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: region.contains("America") ? 100 : 85, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isRegionSelected(region) ? Color.blue : Color.white.opacity(0.1))
                                )
                                .foregroundStyle(isRegionSelected(region) ? .white : .white.opacity(0.8))
                                .scaleEffect(isRegionSelected(region) ? 1.05 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .hoverEffect()
                    }
                    
                    // Country button next in line
                    if case .country(let code, let name) = appModel.chartViewMode {
                        HStack(spacing: 4) {
                            // Add flag emoji if available
                            if let flagEmoji = getFlagEmoji(for: code) {
                                Text(flagEmoji)
                                    .font(.system(size: 14))
                            }
                            Text(name)
                                .font(.system(size: 15, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                        .foregroundStyle(.white)
                        .scaleEffect(1.05)
                        .frame(minWidth: 100, maxWidth: 180)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            // Chart with dual Y-axes
            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { data in
                        // Cases line (scaled)
                        LineMark(
                            x: .value("Year", data.year),
                            y: .value("Cases", scaledCases(data.estimatedCases)),
                            series: .value("Type", "Cases")
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        // Immunization rate line
                        LineMark(
                            x: .value("Year", data.year),
                            y: .value("Rate", data.immunizationRate),
                            series: .value("Type", "Immunization %")
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                    
                    // Vertical line at current year
                    RuleMark(x: .value("Current Year", currentYear))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Current year data points
                    if let yearData = currentYearData {
                        // Cases point
                        PointMark(
                            x: .value("Year", yearData.year),
                            y: .value("Cases", scaledCases(yearData.estimatedCases))
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                        .annotation(
                            position: scaledCases(yearData.estimatedCases) > 85 ? .trailing :
                                     yearData.year >= 2018 ? .topLeading : 
                                     yearData.year <= 1985 ? .topTrailing : .top,
                            alignment: yearData.year >= 2018 ? .trailing : 
                                       yearData.year <= 1985 ? .leading : .center,
                            spacing: 8
                        ) {
                            VStack(spacing: 2) {
                                Text("Cases")
                                    .font(.caption2)
                                    .foregroundStyle(.red.opacity(0.8))
                                Text(numberFormatter.string(from: NSNumber(value: Int(yearData.estimatedCases))) ?? "")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.9))
                            .cornerRadius(4)
                        }
                        
                        // Immunization point
                        PointMark(
                            x: .value("Year", yearData.year),
                            y: .value("Rate", yearData.immunizationRate)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(100)
                        .annotation(
                            position: yearData.immunizationRate < 15 ? .trailing :
                                     yearData.year >= 2018 ? .bottomLeading : 
                                     yearData.year <= 1985 ? .bottomTrailing : .bottom,
                            alignment: yearData.year >= 2018 ? .trailing : 
                                       yearData.year <= 1985 ? .leading : .center,
                            spacing: 8
                        ) {
                            VStack(spacing: 2) {
                                Text("Immunization")
                                    .font(.caption2)
                                    .foregroundStyle(.blue.opacity(0.8))
                                Text("\(Int(yearData.immunizationRate))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.9))
                            .cornerRadius(4)
                        }
                    }
                }
                .chartXScale(domain: 1980...2023)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel {
                            if let year = value.as(Int.self) {
                                Text(String(year))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: casesAxisValues) { value in
                        AxisGridLine()
                            .foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel(casesAxisLabel(value))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 20, 40, 60, 80, 100]) { value in
                        AxisValueLabel("\(Int(value.as(Double.self) ?? 0))%")
                            .foregroundStyle(.blue.opacity(0.8))
                    }
                }
                .chartYScale(domain: -5...105) // Extend scale slightly beyond 0-100
                .frame(height: 300)
                .padding(.horizontal, 35)  // Extra horizontal space for annotations
                .padding(.vertical, 25)    // Extra vertical space for annotations
                .background(.black.opacity(0.3))
                .cornerRadius(12)
            } else {
                // Loading state
                ProgressView("Loading data...")
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.3))
                    .cornerRadius(12)
            }
            
            // Legend
            HStack(spacing: 24) {
                Label("Cases", systemImage: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.red)
                
                // Show appropriate label based on view mode
                switch appModel.chartViewMode {
                case .country(_, let name):
                    Label("Immunization % (\(name))", systemImage: "shield.fill")
                        .foregroundStyle(.blue)
                case .region, .world:
                    Label("Immunization % (Average)", systemImage: "shield.fill")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 900, height: 540)  // Reduced height for tighter layout
        .onAppear {
            loadChartData()
        }
        .onChange(of: appModel.chartViewMode) {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadChartData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentYear = year
                }
            }
        }
    }
}

#Preview {
    CasesVsImmunizationChart()
        .environment(AppModel())
}
