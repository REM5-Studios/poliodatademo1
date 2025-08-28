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
        VStack(spacing: 12) {
            Text("Total Global Cases")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Text(numberFormatter.string(from: NSNumber(value: globalCases)) ?? "0")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 200, height: 80)
        .padding(20)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .offset(z: 30)
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
            
            // Update UI on main actor
            await MainActor.run {
                globalCases = total
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
