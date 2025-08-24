//
//  ContentView.swift
//  Data_Viz_Demo1
//
//  Created by amir berenjian on 8/23/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    @State private var currentYear = 2000

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 12) {
                Text("Polio Data Visualization")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Explore global polio cases from 2000 to 2023")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Main content
            if appModel.immersiveSpaceState == .closed {
                // Show immersive space button
                VStack(spacing: 24) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                        .symbolEffect(.pulse)
                    
                    ToggleImmersiveSpaceButton()
                        .controlSize(.extraLarge)
                        .buttonStyle(.borderedProminent)
                    
                    Text("Enter the immersive experience")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 40)
                .frame(maxHeight: .infinity)
                
            } else {
                // Show control panel
                ControlPanel(currentYear: $currentYear) { year in
                    NotificationCenter.default.post(
                        name: .yearChanged,
                        object: nil,
                        userInfo: ["year": year]
                    )
                }
                .padding(.top, 20)
                .frame(maxHeight: .infinity)
            }
            
            Spacer()
        }
        .frame(width: 700, height: appModel.immersiveSpaceState == .open ? 600 : 500)
    }
}

extension Notification.Name {
    static let yearChanged = Notification.Name("yearChanged")
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
