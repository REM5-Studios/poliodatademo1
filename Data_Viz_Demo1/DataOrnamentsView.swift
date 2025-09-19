//
//  DataOrnamentsView.swift
//  Data_Viz_Demo1
//
//  Container for all data ornaments: Global Cases, Global Immunization, Highest Country
//

import SwiftUI

struct DataOrnamentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            YearDisplayOrnament()
            VStack(spacing: 8) {
                GlobalCasesOrnament()
                GlobalImmunizationOrnament()
                HighestCountryOrnament()
            }
        }
        .frame(width: 360, height: 500)
        .fixedSize()
    }
}

// MARK: - Year Display Ornament

struct YearDisplayOrnament: View {
    @State private var currentYear = 1980
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Year")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            
            Text(String(currentYear))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: 360, height: 60)
        .padding(.vertical, 12)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                currentYear = year
            }
        }
    }
}

// MARK: - Global Immunization Ornament

struct GlobalImmunizationOrnament: View {
    @State private var currentYear = 1980
    @State private var immunizationRate: Double = 0
    @State private var previousYearRate: Double = 0
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    private let dataLoader = DataLoader.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Left half - Title with background
            VStack(spacing: 2) {
                Text("Global Immunization")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Rate")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180, height: 80)
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // Right half - Data
            VStack(spacing: 2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text("\(Int(immunizationRate))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    if previousYearRate > 0 {
                        let percentChange = immunizationRate - previousYearRate
                        let changeText = percentChange >= 0 ? "↑" : "↓"
                        Text("\(changeText) \(abs(Int(percentChange)))% from prior year")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 180, height: 80)
        }
        .frame(width: 360, height: 80)
        .padding(20)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int, year != currentYear && !isLoading {
                currentYear = year
                
                loadingTask?.cancel()
                loadingTask = Task {
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds (synchronized)
                    guard !Task.isCancelled else { return }
                    await updateImmunizationRate(for: year)
                }
            }
        }
        .onAppear {
            loadingTask = Task {
                // Get the current year from the main app
                let initialYear = 1980  // Default to 1980 if no notification received yet
                await updateImmunizationRate(for: initialYear)
            }
        }
        .onDisappear {
            loadingTask?.cancel()
        }
    }
    
    private func updateImmunizationRate(for year: Int) async {
        await MainActor.run { isLoading = true }
        
        // Get the global immunization rate from globalTotals
        let rate = dataLoader.globalTotals.first { $0.year == year }?.immunizationRate ?? 0
        
        // Get previous year rate for comparison
        var previousRate: Double = 0
        if year > 1980 {
            previousRate = dataLoader.globalTotals.first { $0.year == year - 1 }?.immunizationRate ?? 0
        }
        
        await MainActor.run {
            immunizationRate = rate
            previousYearRate = previousRate
            isLoading = false
        }
    }
}

// MARK: - Highest Country Ornament

struct HighestCountryOrnament: View {
    @State private var currentYear = 1980
    @State private var highestCountry = ""
    @State private var countryCases = 0
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    private let dataLoader = DataLoader.shared
    
    // Number formatter
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            // Left half - Title with background
            VStack(spacing: 2) {
                Text("Country with")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Most Cases")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180, height: 80)
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // Right half - Data
            VStack(spacing: 2) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text(highestCountry)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(numberFormatter.string(from: NSNumber(value: countryCases)) ?? "0")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(.numericText())
                }
            }
            .frame(width: 180, height: 80)
        }
        .frame(width: 360, height: 80)
        .padding(20)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int, year != currentYear && !isLoading {
                currentYear = year
                
                loadingTask?.cancel()
                                        loadingTask = Task {
                            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds (synchronized)
                            guard !Task.isCancelled else { return }
                            await updateHighestCountry(for: year)
                        }
            }
        }
        .onAppear {
            loadingTask = Task {
                // Get the current year from the main app
                let initialYear = 1980  // Default to 1980 if no notification received yet
                await updateHighestCountry(for: initialYear)
            }
        }
        .onDisappear {
            loadingTask?.cancel()
        }
    }
    
    private func updateHighestCountry(for year: Int) async {
        await MainActor.run { isLoading = true }
        
        do {
            guard !Task.isCancelled else { 
                await MainActor.run { isLoading = false }
                return 
            }
            
            let yearData = try await dataLoader.loadYear(year)
            
            guard !Task.isCancelled else { 
                await MainActor.run { isLoading = false }
                return 
            }
            
            let excludedCodes = ["OWID_WRL", "OWID_AFR", "OWID_ASI", "OWID_EUR", "OWID_NAM", "OWID_OCE", "OWID_SAM"]
            let countryData = yearData.values.compactMap { data -> (name: String, cases: Int)? in
                guard !excludedCodes.contains(data.code) else { return nil }
                let cases = dataLoader.getActualCases(for: data.code, year: year) ?? data.value
                guard cases > 0 else { return nil }
                let name = dataLoader.countries[data.code]?.name ?? data.entity
                return (name: name, cases: cases)
            }.sorted { $0.cases > $1.cases }
            
            await MainActor.run {
                if let highest = countryData.first {
                    highestCountry = highest.name
                    countryCases = highest.cases
                } else {
                    highestCountry = "No Data"
                    countryCases = 0
                }
                isLoading = false
            }
        } catch {
            print("Highest Country Ornament: Error loading year data for \(year): \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

#Preview {
    DataOrnamentsView()
}
