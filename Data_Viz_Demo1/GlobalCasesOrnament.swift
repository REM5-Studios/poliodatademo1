//
//  GlobalCasesOrnament.swift
//  Data_Viz_Demo1
//
//  Ornament displaying total global polio cases for the current year
//

import SwiftUI

struct GlobalCasesOrnament: View {
    @State private var currentYear = 1980
    @State private var globalCases = 0
    @State private var previousYearCases = 0
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    private let dataLoader = DataLoader.shared
    
    // Number formatter for clean display
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
                Text("Total Global")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Cases")
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
                    Text(numberFormatter.string(from: NSNumber(value: globalCases)) ?? "0")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    if previousYearCases > 0 {
                        let percentChange = ((Double(globalCases) - Double(previousYearCases)) / Double(previousYearCases)) * 100
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int, year != currentYear && !isLoading {
                currentYear = year
                
                // Cancel any existing loading task
                loadingTask?.cancel()
                
                // Create new debounced task
                loadingTask = Task {
                    // Small delay to debounce rapid changes
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
                    
                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }
                    
                    await updateGlobalCases(for: year)
                }
            }
        }
        .onAppear {
            loadingTask = Task {
                // Start with 1980 data
                let initialYear = 1980
                currentYear = initialYear
                await updateGlobalCases(for: initialYear)
            }
        }
        .onDisappear {
            loadingTask?.cancel()
        }
    }
    
    // MARK: - Safe Data Loading
    
    private func updateGlobalCases(for year: Int) async {
        // Set loading state
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Check if task was cancelled before starting
            guard !Task.isCancelled else { 
                await MainActor.run { isLoading = false }
                return 
            }
            
            let yearData = try await dataLoader.loadYear(year)
            
            // Check again if cancelled after loading
            guard !Task.isCancelled else { 
                await MainActor.run { isLoading = false }
                return 
            }
            
            // Calculate global total (excluding regional aggregates)
            let excludedCodes = ["OWID_WRL", "OWID_AFR", "OWID_ASI", "OWID_EUR", "OWID_NAM", "OWID_OCE", "OWID_SAM"]
            let total = yearData.values.compactMap { data -> Int? in
                guard !excludedCodes.contains(data.code) else { return nil }
                return dataLoader.getActualCases(for: data.code, year: year) ?? data.value
            }.reduce(0, +)
            
            // Get previous year data for comparison
            var previousTotal = 0
            if year > 1980 {
                do {
                    let previousYearData = try await dataLoader.loadYear(year - 1)
                    previousTotal = previousYearData.values.compactMap { data -> Int? in
                        guard !excludedCodes.contains(data.code) else { return nil }
                        return dataLoader.getActualCases(for: data.code, year: year - 1) ?? data.value
                    }.reduce(0, +)
                } catch {
                    // If previous year fails, just use 0
                    previousTotal = 0
                }
            }
            
            // Update UI on main actor
            await MainActor.run {
                globalCases = total
                previousYearCases = previousTotal
                isLoading = false
            }
        } catch {
            print("Ornament: Error loading year data for \(year): \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    GlobalCasesOrnament()
}
