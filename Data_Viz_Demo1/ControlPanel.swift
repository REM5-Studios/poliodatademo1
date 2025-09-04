//
//  ControlPanel.swift
//  Data_Viz_Demo1
//
//  Control panel for year selection
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ControlPanel: View {
    @Binding var currentYear: Int
    let onYearChanged: (Int) -> Void
    
    // For smooth slider animation
    @State private var sliderValue: Double = 1980
    
    var body: some View {
        VStack(spacing: 2) { // Very tight spacing for compact 3D use
                Text("Year")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 15) // Reduced top padding
                
                // Smaller year display but still prominent
                Text(String(currentYear))
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: currentYear)
                    .padding(.bottom, 8) // Increased gap below year
                
                // Custom glass sphere slider with tick marks
                VStack(spacing: 6) { // Minimal slider section spacing
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
                    .frame(width: 500, height: 35) // Slightly smaller slider
                    .padding(.top, 12) // Increased gap above slider
                    
                    // Smaller year labels below slider
                    HStack {
                        Text("1980")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("2023")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 500)
                }
                .padding(.bottom, 15) // Minimal bottom padding
        }
        .frame(width: 600, height: 220) // Compact: 600×220 (was 750×440)
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
    
    @ViewBuilder
    private var sphereHandle: some View {
        Model3D(named: "Sphere", bundle: realityKitContentBundle) { model in
            model
                .resizable()
                .frame(width: 39, height: 39) // 30% bigger (30 * 1.3 = 39)
                .scaleEffect(sphereScale)
        } placeholder: {
            // Fallback to 2D circle if 3D model fails to load
            Circle()
                .frame(width: 39, height: 39) // 30% bigger
                .background(.thickMaterial, in: Circle())
                .glassBackgroundEffect(in: Circle())
                .scaleEffect(sphereScale)
        }
        .offset(y: -3) // Move closer to slider
        .offset(z: 15) // Move away from user (was 30, now 15)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
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
                .frame(width: geometry.size.width - 39) // Account for larger sphere width
                .offset(x: 19.5) // Center ticks on track (39/2 = 19.5)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue.gradient)
                    .frame(width: geometry.size.width * normalizedValue, height: 8)
                
                // 3D Glass Sphere Handle
                sphereHandle
                    .offset(x: (geometry.size.width - 39) * normalizedValue)
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
