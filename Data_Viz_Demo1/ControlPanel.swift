//
//  ControlPanel.swift
//  Data_Viz_Demo1
//
//  Control panel for year selection
//

import SwiftUI

struct ControlPanel: View {
    @Binding var currentYear: Int
    let onYearChanged: (Int) -> Void
    
    // For smooth slider animation
    @State private var sliderValue: Double = 1980
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Polio Cases by Year")
                .font(.largeTitle)
                .padding(.top)
            
            // Large year display with smooth animation
            Text(String(currentYear))
                .font(.system(size: 56, weight: .medium, design: .rounded))
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.2), value: currentYear)
            
            // Native visionOS slider with edge labels
            HStack(spacing: 20) {
                Text("1980")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
                
                Slider(value: $sliderValue, in: 1980...2023, step: 1)
                    .frame(width: 350)
                    .tint(.blue)
                    .onChange(of: sliderValue) { _, newValue in
                        let year = Int(newValue)
                        if year != currentYear {
                            currentYear = year
                            onYearChanged(year)
                        }
                    }
                
                Text("2023")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            }
            .padding(.horizontal)
        }
        .frame(width: 600, height: 350)
        .padding()
        .onAppear {
            sliderValue = Double(currentYear)
        }
    }
}
