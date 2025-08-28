//
//  DataOrnamentsView.swift
//  Data_Viz_Demo1
//
//  Container for all data ornaments: Global Cases, Highest Region, Highest Country
//

import SwiftUI

struct DataOrnamentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            GlobalCasesOrnament()
            HighestRegionOrnament()
            HighestCountryOrnament()
        }
    }
}

// MARK: - Highest Region Ornament

struct HighestRegionOrnament: View {
    @State private var currentYear = 1980
    @State private var highestRegion = ""
    @State private var regionCases = 0
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
            Text("Highest Region")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                VStack(spacing: 4) {
                    Text(highestRegion)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                    
                    Text(numberFormatter.string(from: NSNumber(value: regionCases)) ?? "0")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(.numericText())
                }
            }
        }
        .frame(width: 200, height: 80)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .offset(z: 30)
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int, year != currentYear && !isLoading {
                currentYear = year
                
                loadingTask?.cancel()
                                        loadingTask = Task {
                            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds (synchronized)
                            guard !Task.isCancelled else { return }
                            await updateHighestRegion(for: year)
                        }
            }
        }
        .onAppear {
            loadingTask = Task {
                // Get the current year from the main app
                let initialYear = 1980  // Default to 1980 if no notification received yet
                await updateHighestRegion(for: initialYear)
            }
        }
        .onDisappear {
            loadingTask?.cancel()
        }
    }
    
    private func updateHighestRegion(for year: Int) async {
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
            
            // Define regional groupings of country codes
            let regionGroups = [
                "Africa": ["DZA", "AGO", "BEN", "BWA", "BFA", "BDI", "CMR", "CPV", "CAF", "TCD", "COM", "COG", "COD", "DJI", "EGY", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA", "GIN", "GNB", "CIV", "KEN", "LSO", "LBR", "LBY", "MDG", "MWI", "MLI", "MRT", "MUS", "MAR", "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM", "ZAF", "SSD", "SDN", "TZA", "TGO", "TUN", "UGA", "ZMB", "ZWE"],
                "Asia": ["AFG", "ARM", "AZE", "BHR", "BGD", "BTN", "BRN", "KHM", "CHN", "CYP", "GEO", "IND", "IDN", "IRN", "IRQ", "ISR", "JPN", "JOR", "KAZ", "KWT", "KGZ", "LAO", "LBN", "MYS", "MDV", "MNG", "MMR", "NPL", "PRK", "OMN", "PAK", "PSE", "PHL", "QAT", "SAU", "SGP", "KOR", "LKA", "SYR", "TWN", "TJK", "THA", "TLS", "TUR", "TKM", "ARE", "UZB", "VNM", "YEM"],
                "Europe": ["ALB", "AND", "AUT", "BLR", "BEL", "BIH", "BGR", "HRV", "CZE", "DNK", "EST", "FIN", "FRA", "DEU", "GRC", "HUN", "ISL", "IRL", "ITA", "LVA", "LIE", "LTU", "LUX", "MLT", "MDA", "MCO", "MNE", "NLD", "MKD", "NOR", "POL", "PRT", "ROU", "RUS", "SMR", "SRB", "SVK", "SVN", "ESP", "SWE", "CHE", "UKR", "GBR", "VAT"],
                "N. America": ["CAN", "USA", "MEX", "GTM", "BLZ", "SLV", "HND", "NIC", "CRI", "PAN"],
                "S. America": ["ARG", "BOL", "BRA", "CHL", "COL", "ECU", "GUY", "PRY", "PER", "SUR", "URY", "VEN"],
                "Oceania": ["AUS", "FJI", "KIR", "MHL", "FSM", "NRU", "NZL", "PLW", "PNG", "WSM", "SLB", "TON", "TUV", "VUT"]
            ]
            
            // Calculate totals for each region
            var regionTotals: [(name: String, cases: Int)] = []
            
            for (regionName, countryCodes) in regionGroups {
                let regionTotal = countryCodes.compactMap { countryCode in
                    dataLoader.getActualCases(for: countryCode, year: year)
                }.reduce(0, +)
                
                if regionTotal > 0 {
                    regionTotals.append((name: regionName, cases: regionTotal))
                }
            }
            
            // Sort by cases (highest first)
            regionTotals.sort { $0.cases > $1.cases }
            
            await MainActor.run {
                if let highest = regionTotals.first {
                    highestRegion = highest.name
                    regionCases = highest.cases
                } else {
                    highestRegion = "No Data"
                    regionCases = 0
                }
                isLoading = false
            }
        } catch {
            print("Highest Region Ornament: Error loading year data for \(year): \(error)")
            await MainActor.run { isLoading = false }
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
        .frame(width: 200, height: 80)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .offset(z: 30)
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
