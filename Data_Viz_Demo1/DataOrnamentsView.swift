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
            GlobalCasesOrnament()
            GlobalImmunizationOrnament()
            HighestCountryOrnament()
        }
        .frame(width: 280, height: 500)
        .fixedSize()
    }
}

// MARK: - Global Immunization Ornament

struct GlobalImmunizationOrnament: View {
    @State private var currentYear = 1980
    @State private var immunizationRate: Double = 0
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    private let dataLoader = DataLoader.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Global Immunization")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Text("\(Int(immunizationRate))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 280, height: 116)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        
        await MainActor.run {
            immunizationRate = rate
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
        VStack(spacing: 12) {
            Text("Highest Country")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                VStack(spacing: 4) {
                    Text(highestCountry)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(numberFormatter.string(from: NSNumber(value: countryCases)) ?? "0")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(.numericText())
                }
            }
        }
        .frame(width: 280, height: 116)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
