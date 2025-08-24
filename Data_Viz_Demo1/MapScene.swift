//
//  MapScene.swift
//  Data_Viz_Demo1
//
//  RealityKit scene for polio data visualization
//  Creates a tabletop map with 3D bars showing case counts
//

import SwiftUI
import RealityKit
import RealityKitContent
import Spatial

struct MapScene: View {
    @Environment(AppModel.self) var appModel
    @State private var currentYear = 2000
    @State private var mapRig: Entity?
    @State private var barsRoot: Entity?
    @State private var barEntities: [String: ModelEntity] = [:]
    @State private var isDataLoaded = false
    @State private var loadError: String?
    
    // Shared mesh resource for all bars
    @State private var barMesh: MeshResource?
    
    // Map dimensions in meters
    private let mapWidth: Float = 1.2
    private let mapHeight: Float = 0.6
    
    var body: some View {
        RealityView { content in
            // Create world anchor at table height, closer to window
            let worldAnchor = AnchorEntity(world: [0, 0.85, -1.2])
            content.add(worldAnchor)
            
            // Create map rig (parent for all map elements)
            let rig = Entity()
            rig.name = "MapRig"
            worldAnchor.addChild(rig)
            mapRig = rig
            
            // Create map plane
            if let mapEntity = await createMapPlane() {
                rig.addChild(mapEntity)
                
                // Create bars root entity
                let barsContainer = Entity()
                barsContainer.name = "BarsRoot"
                rig.addChild(barsContainer)
                barsRoot = barsContainer
                
                // Load data and create bars
                await loadDataAndCreateBars()
            }
            
            // Enable input for gestures
            rig.components.set(InputTargetComponent())
            rig.components.set(CollisionComponent(shapes: [.generateBox(size: [2, 0.1, 2])]))
            
            // Add gestures to the view
            content.subscribe(to: SceneEvents.Update.self) { _ in
                // This ensures scene is ready
            }
        }
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let rig = self.mapRig else { return }
                    let translation = value.convert(value.translation3D, from: .local, to: rig.parent!)
                    rig.position.x = Float(translation.x)
                    rig.position.z = Float(translation.z)
                }
        )
        .gesture(
            RotateGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let rig = self.mapRig else { return }
                    let rotation = Float(value.rotation.radians)
                    rig.transform.rotation = simd_quatf(angle: rotation, axis: [0, 1, 0])
                }
        )
        .gesture(
            MagnifyGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let rig = self.mapRig else { return }
                    let scale = Float(value.magnification)
                    let clampedScale = min(max(scale, 0.75), 1.5)
                    rig.transform.scale = [clampedScale, clampedScale, clampedScale]
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                Task {
                    await updateBarsForYear(year)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // Data status
            if let error = loadError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    // MARK: - Map Creation
    
    private func createMapPlane() async -> ModelEntity? {
        // Create plane mesh (lies in XY plane initially)
        let planeMesh = MeshResource.generatePlane(
            width: mapWidth,
            height: mapHeight,
            cornerRadius: 0
        )
        
        // Load map texture
        guard let texture = try? await TextureResource(named: "world_equirect") else {
            loadError = "Could not load map texture"
            return nil
        }
        
        // Create unlit material with map texture
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        
        // Create map entity
        let mapEntity = ModelEntity(mesh: planeMesh, materials: [material])
        mapEntity.name = "MapPlane"
        
        // Rotate to lie flat (XZ plane with Y up)
        mapEntity.transform.rotation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        
        // Generate collision shape for tap detection
        mapEntity.generateCollisionShapes(recursive: false)
        
        return mapEntity
    }
    
    // MARK: - Data Loading and Bar Creation
    
    private func loadDataAndCreateBars() async {
        print("MapScene: Starting loadDataAndCreateBars...")
        
        do {
            // Load static data
            try await DataLoader.shared.loadStaticData()
            
            // Create shared bar mesh (reuse for performance)
            // Small base size - we'll scale it up for height
            barMesh = MeshResource.generateBox(size: [0.005, 0.005, 0.005])
            
            // Load initial year data
            print("MapScene: Loading year \(currentYear) data...")
            let yearData = try await DataLoader.shared.loadYear(currentYear)
            
            // Create bars for all countries
            await createAllBars()
            
            // Update bars with year data
            updateBars(with: yearData)
            
            isDataLoaded = true
            print("MapScene: Data loading and bar creation complete!")
            
        } catch {
            loadError = error.localizedDescription
            print("MapScene ERROR: \(error)")
        }
    }
    
    private func createAllBars() async {
        guard let barsRoot = barsRoot,
              let mesh = barMesh else { return }
        
        let centroids = DataLoader.shared.centroids
        _ = DataLoader.shared.bins
        
        // Debug: Create reference markers at corners AND known countries
        if false {  // Set to false to disable debug markers
            // First, let's verify our understanding of the coordinate system
            print("=== COORDINATE SYSTEM DEBUG ===")
            print("Map dimensions: width=\(mapWidth), height=\(mapHeight)")
            print("Plane initially in XY, rotated -90° around X to lie in XZ")
            print("Expected: (0,0) = top-left, (1,0) = top-right, (0,1) = bottom-left, (1,1) = bottom-right")
            
            let debugPositions: [(String, Float, Float, UIColor)] = [
                ("Corner_TL", 0.0, 0.0, .yellow),    // Top-left
                ("Corner_TR", 1.0, 0.0, .yellow),    // Top-right
                ("Corner_BL", 0.0, 1.0, .yellow),    // Bottom-left
                ("Corner_BR", 1.0, 1.0, .yellow),    // Bottom-right
                ("Center", 0.5, 0.5, .yellow),       // Center
                
                // Add specific country positions
                ("BRA_manual", 0.362335, 0.567215, .cyan),     // Brazil
                ("NGA_manual", 0.521, 0.448, .magenta),        // Nigeria (Africa)
                ("IND_manual", 0.720, 0.374, .orange),         // India (Asia)
            ]
            
            for (name, x_norm, y_norm, color) in debugPositions {
                // Use same transformation as country bars
                let localX = (x_norm - 0.5) * mapWidth
                let localZ = (y_norm - 0.5) * mapHeight  // Changed to match country transformation
                
                var material = UnlitMaterial()
                material.color = .init(tint: color)
                
                let debugBar = ModelEntity(mesh: mesh, materials: [material])
                debugBar.name = "Debug_\(name)"
                debugBar.position = [localX, 0.01, localZ]
                debugBar.scale = [2, 20, 2]  // Make them taller and wider
                
                barsRoot.addChild(debugBar)
                
                print("Debug bar \(name): norm(\(x_norm), \(y_norm)) -> local(\(localX), \(localZ))")
            }
        }
        
        // Create a bar entity for each country
        print("MapScene: Creating bars for \(centroids.count) centroids")
        var createdCount = 0
        
        for (code, normalizedPos) in centroids {
            // Skip if not in our countries list
            guard DataLoader.shared.countries[code] != nil else { continue }
            createdCount += 1
            
            // Convert normalized position to local plane coordinates
            // Important: When plane is rotated from XY to XZ, the texture coordinates
            // map directly without inversion. Y becomes Z without flipping.
            let localX = (normalizedPos.x - 0.5) * mapWidth
            let localZ = (normalizedPos.y - 0.5) * mapHeight
            

            
            // Create bar entity
            var material = UnlitMaterial()
            material.color = .init(tint: .white)
            
            let barEntity = ModelEntity(mesh: mesh, materials: [material])
            barEntity.name = "Bar_\(code)"
            
            // Position at centroid (on top of the map plane)
            barEntity.position = [localX, 0.01, localZ]
            

            
            // Start with zero height (scale up from base cube)
            // Scale X and Z by 2 for 10mm × 10mm bars
            barEntity.scale = [2, 0.001, 2]
            
            barsRoot.addChild(barEntity)
            barEntities[code] = barEntity
        }
        
        print("MapScene: Created \(createdCount) bars out of \(centroids.count) centroids")
    }
    
    // MARK: - Bar Updates
    
    private func updateBars(with yearData: [String: YearData]) {
        let bins = DataLoader.shared.bins
        
        print("MapScene: Updating bars with \(yearData.count) year data entries")
        var updatedCount = 0
        
        for (code, barEntity) in barEntities {
            if let data = yearData[code] {
                // Country has cases this year
                let bin = bins[safe: data.bin]
                let height = bin?.height ?? 0.001
                let color = bin?.color ?? .gray
                
                // Update height (bars grow upward)
                // Scale from base cube size (0.005) to desired height
                let scaleY = height / 0.005
                barEntity.scale = [2, scaleY, 2]  // X and Z scaled by 2 for 10mm bars
                barEntity.position.y = 0.01 + (height / 2)
                
                // Update color
                if var material = barEntity.model?.materials.first as? UnlitMaterial {
                    material.color = .init(tint: UIColor(color))
                    barEntity.model?.materials = [material]
                }
                
                // Make visible
                barEntity.isEnabled = true
                
            } else {
                // No cases - hide bar
                barEntity.scale = [2, 0.001, 2]  // Keep X and Z at 2 even when hidden
                barEntity.position.y = 0.01
                barEntity.isEnabled = false
            }
        }
    }
    
    private func updateBarsForYear(_ year: Int) async {
        do {
            let yearData = try await DataLoader.shared.loadYear(year)
            
            // Animate the updates
            await withTaskGroup(of: Void.self) { group in
                for (code, barEntity) in barEntities {
                    group.addTask {
                        await self.animateBarUpdate(
                            barEntity: barEntity,
                            yearData: yearData[code],
                            duration: 0.5
                        )
                    }
                }
            }
        } catch {
            loadError = "Could not load year \(year)"
        }
    }
    
    private func animateBarUpdate(barEntity: ModelEntity, yearData: YearData?, duration: Float) async {
        let bins = DataLoader.shared.bins
        
        let targetHeight: Float
        let targetColor: Color
        
        if let data = yearData {
            let bin = bins[safe: data.bin]
            targetHeight = bin?.height ?? 0.001
            targetColor = bin?.color ?? .gray
        } else {
            targetHeight = 0.001
            targetColor = .gray
        }
        
        // Calculate target values
        let scaleY = targetHeight / 0.005
        let targetY = 0.01 + (targetHeight / 2)
        
        // Store current X and Z positions (these should never change)
        let currentX = barEntity.position.x
        let currentZ = barEntity.position.z
        
        // Cancel any existing animations on this entity
        barEntity.stopAllAnimations()
        
        // Create fresh transform with fixed X and Z
        let targetTransform = Transform(
            scale: [2, scaleY, 2],  // X and Z scaled by 2 for 10mm bars
            rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),  // No rotation
            translation: [currentX, targetY, currentZ]
        )
        
        // Move to target with a clean transform
        barEntity.move(to: targetTransform, relativeTo: nil, duration: TimeInterval(duration))
        
        // Update color
        if var material = barEntity.model?.materials.first as? UnlitMaterial {
            material.color = .init(tint: UIColor(targetColor))
            barEntity.model?.materials = [material]
        }
    }
}

// MARK: - Year Selector UI

struct YearSelector: View {
    @Binding var currentYear: Int
    let onYearChanged: (Int) -> Void
    
    private let years = [2000, 2001, 2002]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(years, id: \.self) { year in
                Button(action: {
                    currentYear = year
                    onYearChanged(year)
                }) {
                    Text("\(year)")
                        .font(.title2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(currentYear == year ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
