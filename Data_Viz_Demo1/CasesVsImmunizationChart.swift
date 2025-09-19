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
    @State private var showingDataInfo = false
    
    // Calculate max cases for scaling with minimum axis range
    private var maxCases: Double {
        let actualMax = chartData.map { $0.estimatedCases }.max() ?? 500000
        let minimumAxisRange = 4000.0  // Minimum 4K range to prevent small numbers looking large
        return max(actualMax, minimumAxisRange)
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
    
    // Calculate axis values for cases (always show nice increments)
    private var casesAxisValues: [Double] {
        if maxCases <= 4000 {
            // When using minimum axis range, show 1K increments: 0, 1K, 2K, 3K, 4K
            [0, 25, 50, 75, 100]  // These map to 0, 1K, 2K, 3K, 4K when maxCases = 4000
        } else {
            // For larger ranges, use the standard 0, 25, 50, 75, 100 scaling
            [0, 25, 50, 75, 100]
        }
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
    
    // Get current decade string (matching YearInfoPanel logic)
    private var currentDecade: String {
        if currentYear >= 2020 {
            return "2020s"
        } else if currentYear >= 2010 {
            return "2010s"
        } else if currentYear >= 2000 {
            return "2000s"
        } else if currentYear >= 1990 {
            return "1990s"
        } else {
            return "1980s"
        }
    }
    
    // Map decades to background images
    private var currentBackgroundImage: String {
        switch currentDecade {
        case "1980s":
            return "polioimage1"  // Keep existing for 1980s
        case "1990s":
            return "polioimage2"
        case "2000s":
            return "polioimage3"
        case "2010s":
            return "polioimage4"
        case "2020s":
            return "polioimage5"
        default:
            return "polioimage1"  // Fallback
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with title and navigation
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Cases vs. Immunization Rate")
                    .font(.system(size: 17, weight: .bold))
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
                    .allowsHitTesting(true)
                    
                    // Region buttons
                    ForEach(["Africa", "Asia", "Europe", "N. America", "S. America"], id: \.self) { region in
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
                        .frame(minWidth: 100, maxWidth: 250)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)  // Extra space between buttons and chart
            .allowsHitTesting(true)  // Ensure buttons remain interactive
            .zIndex(1)  // Keep buttons above chart content
            
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
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // Current year data points
                    if let yearData = currentYearData {
                        // Calculate if labels might overlap (when values are close)
                        let casesValue = scaledCases(yearData.estimatedCases)
                        let immunizationValue = yearData.immunizationRate
                        let valuesAreClose = abs(casesValue - immunizationValue) < 20
                        
                        // Cases point
                        PointMark(
                            x: .value("Year", yearData.year),
                            y: .value("Cases", casesValue)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                        .annotation(
                            position: valuesAreClose ? .topLeading :  // Force separation when close
                                     casesValue > 85 ? .trailing :
                                     yearData.year >= 2018 ? .topLeading : 
                                     yearData.year <= 1985 ? .topTrailing : .top,
                            alignment: yearData.year >= 2018 ? .trailing : 
                                       yearData.year <= 1985 ? .leading : .center,
                            spacing: valuesAreClose ? 12 : 8  // More spacing when close
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
                            y: .value("Rate", immunizationValue)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(100)
                        .annotation(
                            position: valuesAreClose ? .bottomTrailing :  // Force separation when close
                                     immunizationValue < 15 ? .trailing :
                                     yearData.year >= 2018 ? .bottomLeading : 
                                     yearData.year <= 1985 ? .bottomTrailing : .bottom,
                            alignment: yearData.year >= 2018 ? .trailing : 
                                       yearData.year <= 1985 ? .leading : .center,
                            spacing: valuesAreClose ? 12 : 8  // More spacing when close
                        ) {
                            VStack(spacing: 2) {
                                Text("Immunization")
                                    .font(.caption2)
                                    .foregroundStyle(.blue.opacity(0.8))
                                Text("\(Int(immunizationValue))%")
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
                .frame(height: 360)  // Increased from 300 to 360
                .padding(.horizontal, 35)  // Extra horizontal space for annotations
                .padding(.vertical, 25)    // Extra vertical space for annotations
                .background(
                    ZStack {
                        Image(currentBackgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.2)
                            .transition(.opacity.combined(with: .scale(scale: 1.02)))
                            .animation(.easeInOut(duration: 0.4), value: currentBackgroundImage)
                        Color.black.opacity(0.3)
                    }
                )
                .cornerRadius(12)
                .allowsHitTesting(false)  // Chart background shouldn't block interactions
            } else {
                // Loading state
                ProgressView("Loading data...")
                    .frame(height: 360)  // Increased from 300 to 360
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            Image(currentBackgroundImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.2)
                                .transition(.opacity.combined(with: .scale(scale: 1.02)))
                                .animation(.easeInOut(duration: 0.4), value: currentBackgroundImage)
                            Color.black.opacity(0.3)
                        }
                    )
                    .cornerRadius(12)
                    .allowsHitTesting(false)  // Loading state shouldn't block interactions
            }
            
            Spacer()  // Push definitions and citation to bottom
            
            // Data definitions and citation at bottom
            VStack(alignment: .leading, spacing: 4) {
                // Data definitions
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cases: Estimated paralytic polio cases including both wild and vaccine-derived poliovirus")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("Immunization %: Share of one-year-olds who received third dose of polio vaccine")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Data citation with info button
                HStack(spacing: 8) {
                    Text("Data: WHO & UNICEF (2025), UN World Population Prospects (2024), WHO (2019, 2024) – processed by Our World in Data")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Button(action: {
                        showingDataInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.callout)  // Bigger button
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect()  // visionOS hover feedback
                    .popover(isPresented: $showingDataInfo) {
                        VStack(alignment: .center, spacing: 16) {
                            HStack {
                                Text("Data Sources & Details")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingDataInfo = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cases Data:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("• Estimated paralytic polio cases, not just reported cases")
                                Text("• Includes both wild poliovirus and vaccine-derived cases")
                                Text("• Uses correction factors from Tebbens et al. (2010) to account for underreporting")
                                
                                Text("Immunization Data:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)
                                Text("• Specifically measures third dose (Pol3) coverage")
                                Text("• Indicates completion of primary immunization series")
                                Text("• Global/regional rates are population-weighted averages")
                                Text("• ~5% of countries require data extrapolation annually")
                                
                                Text("Data Sources:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Link("WHO & UNICEF Global Polio Data", destination: URL(string: "https://immunizationdata.who.int/")!)
                                        .font(.subheadline)
                                    
                                    Link("Our World in Data - Polio", destination: URL(string: "https://ourworldindata.org/polio")!)
                                        .font(.subheadline)
                                    
                                    Link("Global Polio Eradication Initiative", destination: URL(string: "https://polioeradication.org/")!)
                                        .font(.subheadline)
                                    
                                    Link("UN World Population Prospects", destination: URL(string: "https://population.un.org/wpp/")!)
                                        .font(.subheadline)
                                }
                            }
                            .font(.body)
                        }
                        .padding(24)
                        .frame(width: 480)  // Wider popup
                        .frame(maxWidth: .infinity)  // Center content
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(width: 900, height: 600)  // Increased height to accommodate larger chart
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
