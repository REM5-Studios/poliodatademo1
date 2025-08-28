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
    @State private var currentYear = 1980

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 12) {
                Text("Polio Data Visualization")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Explore global polio cases from 1980 to 2023")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 30)
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
                
                // Reset map position button (center) - HIDDEN
                // HStack {
                //     Spacer()
                //     
                //     Button(action: {
                //         NotificationCenter.default.post(
                //             name: .resetMapPosition,
                //             object: nil
                //         )
                //     }) {
                //         Label("Reset Map Position", systemImage: "arrow.counterclockwise")
                //             .font(.callout)
                //     }
                //     .buttonStyle(.bordered)
                //     .controlSize(.regular)
                //     .padding(.bottom, 10)
                //     
                //     Spacer()
                // }
            }
            
            Spacer()
        }
        .frame(width: 750, height: appModel.immersiveSpaceState == .open ? 600 : 500)
        .ornament(
            attachmentAnchor: .scene(.trailing),
            contentAlignment: .center
        ) {
            if appModel.immersiveSpaceState == .open {
                DataOrnamentsView()
            }
        }
    }
}

extension Notification.Name {
    static let yearChanged = Notification.Name("yearChanged")
    static let resetMapPosition = Notification.Name("resetMapPosition")
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
