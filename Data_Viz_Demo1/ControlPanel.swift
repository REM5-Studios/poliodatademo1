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
        VStack(spacing: 5) { // Further reduced for tighter feel
                Text("Year")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 30) // Slightly increased top padding
                
                // Large year display with smooth animation
                Text(String(currentYear))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: currentYear)
                    .padding(.bottom, 5) // Add small bottom padding to year
                
                // Remove spacer and let VStack handle spacing naturally
                
                // Custom glass sphere slider with tick marks
                VStack(spacing: 12) { // Reduced slider section spacing
                    SimplifiedSphereSlider(
                        value: $sliderValue,
                        range: 1980...2023,
                        step: 1,
                        onChanged: { newValue in
                            let year = Int(newValue)
                            if year != currentYear {
                                currentYear = year
                                onYearChanged(year)
                            }
                        }
                    )
                    .frame(width: 600, height: 40)
                    .padding(.top, 10) // Add small top padding to slider
                    
                    // Year labels below slider
                    HStack {
                        Text("1980")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("2023")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 600)
                }
                .padding(.bottom, 35) // Increased bottom padding for better balance
        }
        .frame(width: 750, height: 440)
        .onAppear {
            sliderValue = Double(currentYear)
        }
    }
}

// MARK: - Simplified Glass Sphere Slider with Tick Marks

struct SimplifiedSphereSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onChanged: (Double) -> Void
    
    @State private var isDragging = false
    @State private var sphereScale: CGFloat = 1.0
    
    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary.opacity(0.3))
                    .frame(height: 8)
                
                // Tick marks every 5 years (Option B)
                HStack(spacing: 0) {
                    ForEach(Array(stride(from: 1980, through: 2020, by: 5).enumerated()), id: \.offset) { index, year in
                        Rectangle()
                            .frame(width: 1.5, height: 6)
                            .foregroundStyle(.secondary.opacity(0.7))
                            .offset(y: -7) // Position above track
                        
                        if index < 8 { // Not after the last tick
                            Spacer()
                        }
                    }
                }
                .frame(width: geometry.size.width - 30) // Account for sphere width
                .offset(x: 15) // Center ticks on track
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue.gradient)
                    .frame(width: geometry.size.width * normalizedValue, height: 8)
                
                // Simplified visionOS Glass Circle
                Circle()
                    .frame(width: 30, height: 30)
                    .background(.thickMaterial, in: Circle())
                    .glassBackgroundEffect(in: Circle())
                    .offset(z: 30)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(sphereScale)
                    .offset(x: (geometry.size.width - 30) * normalizedValue)
                    .offset(y: isDragging ? -5 : 0) // Lift effect when dragging
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: sphereScale)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    sphereScale = 1.3 // Grow when grabbed
                                }
                                
                                let newPosition = min(max(0, gesture.location.x / geometry.size.width), 1)
                                let newValue = range.lowerBound + newPosition * (range.upperBound - range.lowerBound)
                                let steppedValue = round(newValue / step) * step
                                
                                value = steppedValue
                                onChanged(steppedValue)
                            }
                            .onEnded { _ in
                                isDragging = false
                                sphereScale = 1.0 // Return to normal size
                            }
                    )
            }
        }
    }
}
