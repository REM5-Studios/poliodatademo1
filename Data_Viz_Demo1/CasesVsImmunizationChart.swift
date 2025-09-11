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
    @State private var selectedRegion = "World"
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
            selectedRegion = "World"
        case .region(let region):
            chartData = dataLoader.getRegionalData(for: region)
            selectedRegion = region
        case .country(let code, _):
            chartData = dataLoader.getCountryData(for: code)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and navigation
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Cases vs. Immunization Rate")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                // Current selection display with navigation
                HStack(spacing: 12) {
                    // World button (always visible)
                    Button(action: {
                        appModel.chartViewMode = .world
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                            Text("World")
                                .font(.system(size: 16, weight: appModel.chartViewMode == .world ? .bold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(appModel.chartViewMode == .world ? Color.blue : Color.white.opacity(0.1))
                        )
                        .foregroundStyle(appModel.chartViewMode == .world ? .white : .white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    // Show arrow and current selection if not on world view
                    if appModel.chartViewMode != .world {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        // Current selection
                        switch appModel.chartViewMode {
                        case .region(let regionName):
                            HStack(spacing: 4) {
                                Image(systemName: "map")
                                    .font(.system(size: 14))
                                Text(regionName)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                            )
                            .foregroundStyle(.white)
                            
                        case .country(_, let name):
                            HStack(spacing: 4) {
                                Image(systemName: "flag")
                                    .font(.system(size: 14))
                                Text(name)
                                    .font(.system(size: 16, weight: .bold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                            )
                            .foregroundStyle(.white)
                            
                        case .world:
                            EmptyView()
                        }
                    }
                    
                    Spacer()
                }
                
                // Region quick access buttons (only show when on World view)
                if appModel.chartViewMode == .world {
                    HStack(spacing: 12) {
                        Text("Select Region:")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.trailing, 4)
                        
                        ForEach(["Africa", "Asia", "Europe", "North America", "South America", "Oceania"], id: \.self) { region in
                            Button(action: {
                                appModel.chartViewMode = .region(region)
                            }) {
                                Text(region)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .hoverEffect()
                        }
                    }
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
                        .annotation(position: .top, alignment: .center, spacing: 8) {
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
                        .annotation(position: .bottom, alignment: .center, spacing: 8) {
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
                .padding()
                .background(.black.opacity(0.3))
                .cornerRadius(12)
                .padding(.vertical, 20) // Extra vertical space for annotations
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
        .padding()
        .frame(width: 825, height: 520)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
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
