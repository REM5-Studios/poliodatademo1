//
//  DataLoader.swift
//  Data_Viz_Demo1
//
//  Data loading for polio visualization
//  Handles CSV and JSON parsing for bins, countries, centroids, and year data
//

import Foundation
import SwiftUI

// MARK: - Data Models

struct Bin {
    let level: Int
    let edgeMax: Int?
    let height: Float
    let color: Color
}

struct Country {
    let code: String
    let name: String
}

struct YearData {
    let code: String
    let entity: String
    let value: Int
    let bin: Int
}

struct Centroid {
    let code: String
    let normalizedPosition: SIMD2<Float> // x_norm, y_norm for equirectangular
}

struct GlobalTotals: Identifiable {
    let id: Int // Use year as the unique identifier
    let year: Int
    let estimatedCases: Double
    let immunizationRate: Double
    let funding: Double? // Optional since some years don't have funding data
    
    init(year: Int, estimatedCases: Double, immunizationRate: Double, funding: Double?) {
        self.id = year
        self.year = year
        self.estimatedCases = estimatedCases
        self.immunizationRate = immunizationRate
        self.funding = funding
    }
}

struct TimelineEntry {
    let year: Int
    let category: String
    let headline: String
    let subtext: String
}

struct RegionalData: Identifiable {
    let id: String
    let entity: String
    let code: String
    let year: Int
    let cases: Double
    let immunizationRate: Double
}

// MARK: - DataLoader

@Observable
final class DataLoader {
    static let shared = DataLoader()
    
    // Loaded data
    private(set) var bins: [Bin] = []
    private(set) var countries: [String: Country] = [:]
    private(set) var centroids: [String: SIMD2<Float>] = [:]
    private(set) var currentYearData: [String: YearData] = [:]
    private var caseCounts: [String: [String: Int]] = [:] // year -> country -> cases
    private(set) var globalTotals: [GlobalTotals] = [] // Global totals data for charts
    private(set) var regionalData: [RegionalData] = [] // Regional data for filtered charts
    private(set) var timeline: [Int: TimelineEntry] = [:] // Timeline data for year info
    private var countryVaccination: [String: [String: Double]] = [:] // year -> country -> vaccination %
    
    // Loading state
    private(set) var isLoaded = false
    private(set) var loadError: Error?
    
    // Concurrency protection + simple caching (MainActor for simplicity)
    private var staticDataTask: Task<Void, Error>?
    private var yearLoadTasks: [Int: Task<[String: YearData], Error>] = [:]
    private var yearDataCache: [Int: [String: YearData]] = [:] // Simple LRU cache
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load all static data (bins, countries, centroids)
    func loadStaticData() async throws {
        // Return immediately if already loaded
        if isLoaded { return }
        
        // If already loading, wait for existing task
        if let existingTask = staticDataTask {
            return try await existingTask.value
        }
        
        // Create new loading task
        let task = Task<Void, Error> {
            print("DataLoader: Starting static data load...")
            
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await self.loadBins() }
                group.addTask { try await self.loadCountries() }
                group.addTask { try await self.loadCentroids() }
                group.addTask { try await self.loadCaseCounts() }
                group.addTask { try await self.loadGlobalTotals() }
                group.addTask { try await self.loadRegionalData() }
                group.addTask { try await self.loadTimeline() }
                group.addTask { try await self.loadCountryVaccination() }
                
                try await group.waitForAll()
            }
            
            self.isLoaded = true
            print("DataLoader: Static data load complete! Bins: \(self.bins.count), Countries: \(self.countries.count), Centroids: \(self.centroids.count)")
        }
        
        staticDataTask = task
        
        do {
            try await task.value
        } catch {
            staticDataTask = nil // Clear failed task
            loadError = error
            print("DataLoader ERROR: \(error)")
            throw error
        }
    }
    
    /// Load data for a specific year (bulletproof concurrency protection)
    @MainActor
    func loadYear(_ year: Int) async throws -> [String: YearData] {
        // Check cache first (instant return for recent years)
        if let cachedData = yearDataCache[year] {
            print("DataLoader: Cache hit for year \(year)")
            return cachedData
        }
        
        // If already loading this year, wait for existing task
        if let existingTask = yearLoadTasks[year] {
            return try await existingTask.value
        }
        
        // Create new loading task (single file access point)
        print("DataLoader: Starting new load for year \(year)")
        let task = Task<[String: YearData], Error> {
            return try await self._loadYearData(year)
        }
        
        yearLoadTasks[year] = task
        
        do {
            let result = try await task.value
            yearDataCache[year] = result // Cache successful result
            yearLoadTasks.removeValue(forKey: year) // Clean up completed task
            
            // Simple cache limit (keep last 20 years for better performance)
            let maxCacheSize = 20 // Increased for better user experience (only ~60KB total)
            if yearDataCache.count > maxCacheSize {
                let oldestYear = yearDataCache.keys.min() ?? year
                yearDataCache.removeValue(forKey: oldestYear)
                print("DataLoader: Cache evicted year \(oldestYear)")
            }
            
            return result
        } catch {
            yearLoadTasks.removeValue(forKey: year) // Clean up failed task
            throw error
        }
    }
    
    // Private implementation
    private func _loadYearData(_ year: Int) async throws -> [String: YearData] {
        let fileName = "year_\(year)"
        
        // Try both with and without DataFiles subdirectory
        var url = Bundle.main.url(forResource: fileName, withExtension: "csv", subdirectory: "DataFiles")
        if url == nil {
            url = Bundle.main.url(forResource: fileName, withExtension: "csv")
        }
        guard let url = url else {
            print("ERROR: Could not find \(fileName).csv in bundle or DataFiles subdirectory")
            throw DataLoaderError.fileNotFound(fileName)
        }
        
        print("DataLoader: Loading year \(year) from: \(url.path)")
        
        let data = try Data(contentsOf: url)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw DataLoaderError.invalidEncoding
        }
        
        var yearData: [String: YearData] = [:]
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else { continue }
            
            let code = components[0]
            var entity: String
            var value: Int
            var bin: Int
            
            if components.count >= 4 {
                // 4-column format: Code,Entity,Value,Bin (years 2000-2002)
                entity = components[1]
                value = Int(components[2]) ?? 0
                guard let binValue = Int(components[3]) else { continue }
                bin = binValue
            } else {
                // 2-column format: Code,Bin (years 2003+)
                guard let binValue = Int(components[1]) else { continue }
                bin = binValue
                entity = countries[code]?.name ?? code
                value = 0  // We'll use the actual lookup for display
            }
            
            yearData[code] = YearData(code: code, entity: entity, value: value, bin: bin)
        }
        
        currentYearData = yearData
        print("DataLoader: Loaded \(yearData.count) entries for year \(year)")
        return yearData
    }
    
    /// Get actual case count for a specific country and year
    func getActualCases(for countryCode: String, year: Int) -> Int? {
        return caseCounts[String(year)]?[countryCode]
    }
    
    /// Get vaccination rate for a specific country and year
    func getVaccinationRate(for countryCode: String, year: Int) -> Double? {
        return countryVaccination[String(year)]?[countryCode]
    }
    
    // MARK: - Private Loading Methods
    
    private func loadBins() async throws {
        // Try both with and without DataFiles subdirectory
        var url = Bundle.main.url(forResource: "bins", withExtension: "csv", subdirectory: "DataFiles")
        if url == nil {
            url = Bundle.main.url(forResource: "bins", withExtension: "csv")
        }
        guard let url = url else {
            throw DataLoaderError.fileNotFound("bins.csv")
        }
        
        let data = try Data(contentsOf: url)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw DataLoaderError.invalidEncoding
        }
        
        var loadedBins: [Bin] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 4 else { continue }
            
            guard let level = Int(components[0]),
                  let height = Float(components[2]) else { continue }
            
            let edgeMax = components[1].isEmpty ? nil : Int(components[1])
            let colorHex = components[3]
            
            let color = Color(hex: colorHex) ?? .gray
            loadedBins.append(Bin(level: level, edgeMax: edgeMax, height: height, color: color))
        }
        
        // Sort by level to ensure proper indexing
        bins = loadedBins.sorted { $0.level < $1.level }
    }
    
    private func loadCountries() async throws {
        // Try both with and without DataFiles subdirectory
        var url = Bundle.main.url(forResource: "countries", withExtension: "csv", subdirectory: "DataFiles")
        if url == nil {
            url = Bundle.main.url(forResource: "countries", withExtension: "csv")
        }
        guard let url = url else {
            throw DataLoaderError.fileNotFound("countries.csv")
        }
        
        let data = try Data(contentsOf: url)
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw DataLoaderError.invalidEncoding
        }
        
        var loadedCountries: [String: Country] = [:]
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else { continue }
            
            let code = components[0]
            let name = components[1]
            loadedCountries[code] = Country(code: code, name: name)
        }
        
        countries = loadedCountries
    }
    
    private func loadCentroids() async throws {
        // Try both with and without DataFiles subdirectory
        var url = Bundle.main.url(forResource: "centroids", withExtension: "json", subdirectory: "DataFiles")
        if url == nil {
            url = Bundle.main.url(forResource: "centroids", withExtension: "json")
        }
        guard let url = url else {
            throw DataLoaderError.fileNotFound("centroids.json")
        }
        
        let data = try Data(contentsOf: url)
        let jsonDict = try JSONDecoder().decode([String: [Float]].self, from: data)
        
        var loadedCentroids: [String: SIMD2<Float>] = [:]
        for (code, coords) in jsonDict {
            guard coords.count >= 2 else { continue }
            loadedCentroids[code] = SIMD2<Float>(coords[0], coords[1])
        }
        
        centroids = loadedCentroids
    }
    
    private func loadCaseCounts() async throws {
        // Try both with and without DataFiles subdirectory
        var url = Bundle.main.url(forResource: "case_counts", withExtension: "json", subdirectory: "DataFiles")
        if url == nil {
            url = Bundle.main.url(forResource: "case_counts", withExtension: "json")
        }
        guard let url = url else {
            print("Warning: case_counts.json not found - popup will show approximate values")
            return // This is optional data, so don't throw error
        }
        
        let data = try Data(contentsOf: url)
        caseCounts = try JSONDecoder().decode([String: [String: Int]].self, from: data)
        
        let totalCases = caseCounts.values.flatMap { $0.values }.reduce(0, +)
        print("DataLoader: Loaded case counts - \(caseCounts.count) years, \(totalCases) total cases")
    }
    
    private func loadGlobalTotals() async throws {
        // Try to find the global totals CSV file
        var url = Bundle.main.url(forResource: "Global_Polio_Totals_Simplified__1980_2023_", withExtension: "csv", subdirectory: "WorkingFiles/RawData")
        if url == nil {
            url = Bundle.main.url(forResource: "Global_Polio_Totals_Simplified__1980_2023_", withExtension: "csv")
        }
        guard let url = url else {
            throw DataLoaderError.fileNotFound("Global_Polio_Totals_Simplified__1980_2023_.csv")
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Skip header line
        var totals: [GlobalTotals] = []
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            
            guard columns.count >= 4 else { continue }
            
            // Parse the data: ,Year,estimated_paralytic_cases,immunization_rate_pct,funding_total_usd_constant_2021
            guard let year = Int(columns[1]),
                  let cases = Double(columns[2]),
                  let immunizationRate = Double(columns[3]) else { continue }
            
            // Funding is optional (empty for some years)
            let funding = columns.count > 4 && !columns[4].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Double(columns[4]) : nil
            
            totals.append(GlobalTotals(
                year: year,
                estimatedCases: cases,
                immunizationRate: immunizationRate,
                funding: funding
            ))
        }
        
        self.globalTotals = totals
        print("DataLoader: Loaded global totals for \(totals.count) years")
    }
    
    private func loadRegionalData() async throws {
        // Try to find the regional data CSV file
        // Note: Xcode copies all data files to the root of the bundle
        var url = Bundle.main.url(forResource: "regional_polio_data", withExtension: "csv")
        if url == nil {
            // Fallback to DataFiles subdirectory for future compatibility
            url = Bundle.main.url(forResource: "regional_polio_data", withExtension: "csv", subdirectory: "DataFiles")
        }
        
        // If not in bundle, try to load from the raw data file we have
        if url == nil {
            // Use the raw data file directly
            let rawDataURL = Bundle.main.url(forResource: "number-of-estimated-paralytic-polio-cases-by-world-region", withExtension: "csv", subdirectory: "WorkingFiles/RawData")
            print("DataLoader: Checking for raw data file: \(rawDataURL != nil)")
            if let rawDataURL = rawDataURL {
                print("DataLoader: Using raw regional data file")
                try await loadRegionalFromRawData(rawDataURL)
                print("DataLoader: Loaded \(regionalData.count) regional data entries")
                return
            }
        }
        
        guard let url = url else {
            print("DataLoader: Warning - regional_polio_data.csv not found, using global totals only")
            return
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Skip header line
        var regional: [RegionalData] = []
        for (index, line) in lines.dropFirst().enumerated() {
            let columns = line.components(separatedBy: ",")
            
            guard columns.count >= 5 else { 
                continue 
            }
            
            // Parse the data: Year,cases,Entity,Code,immunization_rate_pct
            guard let year = Int(columns[0]),
                  let cases = Double(columns[1]) else { 
                continue 
            }
            let entity = columns[2]
            let code = columns[3]
            
            // Immunization rate is in column 4
            let immunizationRate = Double(columns[4]) ?? 0
            
            regional.append(RegionalData(
                id: "\(code)-\(year)",
                entity: entity,
                code: code,
                year: year,
                cases: cases,
                immunizationRate: immunizationRate
            ))
        }
        
        self.regionalData = regional
        print("DataLoader: Loaded regional data with \(regional.count) entries")
    }
    
    // Helper method to get data for a specific region
    func getRegionalData(for region: String) -> [GlobalTotals] {
        let regionCode = region == "World" ? "WORLD" : region.uppercased().replacingOccurrences(of: " ", with: "_")
        let filtered = regionalData.filter { $0.code == regionCode }
        
        // Convert to GlobalTotals format for chart compatibility
        return filtered.map { data in
            GlobalTotals(
                year: data.year,
                estimatedCases: data.cases,
                immunizationRate: data.immunizationRate,
                funding: nil
            )
        }.sorted { $0.year < $1.year }
    }
    
    // Helper method to get data for a specific country
    func getCountryData(for countryCode: String) -> [GlobalTotals] {
        var countryData: [GlobalTotals] = []
        
        // Get case data from caseCounts
        for (yearStr, countryCases) in caseCounts {
            if let year = Int(yearStr),
               let cases = countryCases[countryCode] {
                // Get country-specific immunization rate if available
                let immunizationRate: Double
                if let countryRate = countryVaccination[yearStr]?[countryCode] {
                    immunizationRate = countryRate
                } else {
                    // Fallback to global average if country data not available
                    immunizationRate = globalTotals.first { $0.year == year }?.immunizationRate ?? 0
                }
                
                countryData.append(GlobalTotals(
                    year: year,
                    estimatedCases: Double(cases),
                    immunizationRate: immunizationRate,
                    funding: nil
                ))
            }
        }
        
        return countryData.sorted { $0.year < $1.year }
    }
    
    private func loadRegionalFromRawData(_ url: URL) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var regional: [RegionalData] = []
        
        // Process all regional entries (those without country codes, including World)
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 4 else { continue }
            
            let entity = columns[0]
            let code = columns[1]
            guard let year = Int(columns[2]),
                  let cases = Double(columns[3]) else { continue }
            
            // Only process regional aggregates (no country code) including World
            if code.isEmpty {
                let regionCode = entity == "World" ? "WORLD" : entity.uppercased().replacingOccurrences(of: " ", with: "_")
                
                // Get immunization rate from global totals
                let immunizationRate = globalTotals.first { $0.year == year }?.immunizationRate ?? 0
                
                regional.append(RegionalData(
                    id: "\(regionCode)-\(year)",
                    entity: entity,
                    code: regionCode,
                    year: year,
                    cases: cases,
                    immunizationRate: immunizationRate
                ))
            }
        }
        
        self.regionalData = regional
        print("DataLoader: Loaded regional data from raw file with \(regional.count) entries")
        
        // Debug: print unique regions found
        let uniqueRegions = Set(regional.map { $0.entity })
        print("DataLoader: Found regions: \(uniqueRegions.sorted())")
    }
    
    private func loadCountryVaccination() async throws {
        // Try to find the vaccination CSV file
        var url = Bundle.main.url(forResource: "polio-vaccine-coverage-of-one-year-olds", withExtension: "csv", subdirectory: "DataFiles")
        if url == nil {
            // Try the raw data location
            url = Bundle.main.url(forResource: "polio-vaccine-coverage-of-one-year-olds", withExtension: "csv", subdirectory: "WorkingFiles/FinalDataRaw")
        }
        
        // If not in bundle, load from file system
        if url == nil {
            let fileSystemPath = "/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1/Data_Viz_Demo1/WorkingFiles/FinalDataRaw/polio-vaccine-coverage-of-one-year-olds.csv"
            if FileManager.default.fileExists(atPath: fileSystemPath) {
                url = URL(fileURLWithPath: fileSystemPath)
            }
        }
        
        guard let fileURL = url else {
            print("DataLoader: Country vaccination file not found")
            return
        }
        
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Skip header and process data
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 4,
                  let year = Int(columns[2]),
                  let rate = Double(columns[3]) else { continue }
            
            let code = columns[1]
            
            // Skip regional aggregates (empty codes)
            guard !code.isEmpty && !code.contains("OWID") else { continue }
            
            // Initialize year dictionary if needed
            if countryVaccination[String(year)] == nil {
                countryVaccination[String(year)] = [:]
            }
            
            // Store vaccination rate
            countryVaccination[String(year)]?[code] = rate
        }
        
        print("DataLoader: Loaded country vaccination data for \(countryVaccination.count) years")
        if let year2023 = countryVaccination["2023"] {
            print("DataLoader: Sample - 2023 has vaccination data for \(year2023.count) countries")
        }
    }
    
    private func loadTimeline() async throws {
        // Load timeline from JSON file
        // Note: Xcode copies all data files to the root of the bundle
        var url = Bundle.main.url(forResource: "polio_timeline_categories", withExtension: "json")
        if url == nil {
            // Fallback to DataFiles subdirectory for future compatibility
            url = Bundle.main.url(forResource: "polio_timeline_categories", withExtension: "json", subdirectory: "DataFiles")
        }
        
        guard let fileURL = url else {
            print("DataLoader: Timeline file not found in bundle")
            // Try to load from file system as fallback
            let fileSystemPath = "/Users/amir/Documents/Amir AVP 2025 Projects/Data_Viz_Demo1/Data_Viz_Demo1/DataFiles/polio_timeline_categories.json"
            if FileManager.default.fileExists(atPath: fileSystemPath) {
                print("DataLoader: Loading timeline from file system")
                let data = try Data(contentsOf: URL(fileURLWithPath: fileSystemPath))
                try parseTimelineData(data)
            }
            return
        }
        
        let data = try Data(contentsOf: fileURL)
        try parseTimelineData(data)
    }
    
    private func parseTimelineData(_ data: Data) throws {
        // Parse JSON as dictionary with year strings as keys
        if let timelineDict = try JSONSerialization.jsonObject(with: data) as? [String: [String: String]] {
            // Convert to our timeline format
            for (yearString, data) in timelineDict {
                if let year = Int(yearString),
                   let category = data["category"],
                   let headline = data["headline"],
                   let subtext = data["subtext"] {
                    timeline[year] = TimelineEntry(
                        year: year,
                        category: category,
                        headline: headline,
                        subtext: subtext
                    )
                }
            }
        }
        
        print("DataLoader: Loaded \(timeline.count) timeline entries")
        if timeline.count > 0 {
            print("DataLoader: Timeline years: \(timeline.keys.sorted())")
            print("DataLoader: Sample entry for 2012: \(timeline[2012]?.headline ?? "Not found")")
        }
    }
}

// MARK: - Error Types

enum DataLoaderError: LocalizedError {
    case fileNotFound(String)
    case invalidEncoding
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find file: \(filename)"
        case .invalidEncoding:
            return "Could not decode file as UTF-8"
        case .invalidFormat(let details):
            return "Invalid file format: \(details)"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        if length == 6 {
            // RGB
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            // RGBA
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}
