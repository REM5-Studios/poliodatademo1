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

// MARK: - DataLoader

@Observable
final class DataLoader {
    static let shared = DataLoader()
    
    // Loaded data
    private(set) var bins: [Bin] = []
    private(set) var countries: [String: Country] = [:]
    private(set) var centroids: [String: SIMD2<Float>] = [:]
    private(set) var currentYearData: [String: YearData] = [:]
    
    // Loading state
    private(set) var isLoaded = false
    private(set) var loadError: Error?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load all static data (bins, countries, centroids)
    func loadStaticData() async throws {
        print("DataLoader: Starting static data load...")
        
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await self.loadBins() }
                group.addTask { try await self.loadCountries() }
                group.addTask { try await self.loadCentroids() }
                
                try await group.waitForAll()
            }
            isLoaded = true
            print("DataLoader: Static data load complete! Bins: \(bins.count), Countries: \(countries.count), Centroids: \(centroids.count)")
        } catch {
            loadError = error
            print("DataLoader ERROR: \(error)")
            throw error
        }
    }
    
    /// Load data for a specific year
    func loadYear(_ year: Int) async throws -> [String: YearData] {
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
                value = bin > 0 ? 1 : 0
            }
            
            yearData[code] = YearData(code: code, entity: entity, value: value, bin: bin)
        }
        
        currentYearData = yearData
        print("DataLoader: Loaded \(yearData.count) entries for year \(year)")
        return yearData
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
