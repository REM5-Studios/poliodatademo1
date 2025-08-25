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
    @State private var currentYear = 1980
    @State private var mapRig: Entity?
    @State private var barsRoot: Entity?
    @State private var barEntities: [String: ModelEntity] = [:]
    @State private var isDataLoaded = false
    @State private var loadError: String?
    
    // Shared mesh resource for all bars
    @State private var barMesh: MeshResource?
    
    // Interaction states
    @State private var hoveredCountryCode: String?
    @State private var selectedCountryCode: String?
    @State private var currentYearData: [String: YearData] = [:]
    @State private var infoBoxEntity: Entity?
    
    // Map dimensions in meters
    private let mapWidth: Float = 1.2
    private let mapHeight: Float = 0.6
    
    // 3D map entity
    @State private var map3DEntity: Entity?
    
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
                
                // Add 3D map
                if let map3D = await create3DMap() {
                    rig.addChild(map3D)
                    map3DEntity = map3D
                }
                
                // Create bars root entity
                let barsContainer = Entity()
                barsContainer.name = "BarsRoot"
                rig.addChild(barsContainer)
                barsRoot = barsContainer
                
                // Load data and create bars
                await loadDataAndCreateBars()
            }
            

        }
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                currentYear = year
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
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Check if it's a bar by looking at the name
                    if value.entity.name.hasPrefix("Bar_") {
                        let countryCode = String(value.entity.name.dropFirst(4))
                        handleBarTap(countryCode: countryCode)
                    }
                }
        )

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
        
        // Hide the 2D map plane (set opacity to 1.0 to show it again)
        mapEntity.components.set(OpacityComponent(opacity: 0.0))
        
        // Generate collision shape for tap detection
        mapEntity.generateCollisionShapes(recursive: false)
        
        return mapEntity
    }
    
    // MARK: - 3D Map Creation
    
    private func create3DMap() async -> Entity? {
        do {
            // Load the 3D map model from RealityKitContent
            let map3D = try await Entity(named: "WorldMap3D", in: realityKitContentBundle)
            map3D.name = "Map3D"
            
            // Scale to match the 2D map dimensions (adjust these values as needed)
            // The 2D map is 1.2m × 0.6m
            let targetWidth: Float = mapWidth  // 1.2 meters
            
            // Get the model's bounding box to calculate proper scaling
            let bounds = map3D.visualBounds(relativeTo: nil)
            let modelWidth = bounds.max.x - bounds.min.x
            let scaleFactor = targetWidth / modelWidth
            map3D.scale = [scaleFactor, scaleFactor, scaleFactor]
            
            // Rotate to lie flat (same as 2D map - rotate 90 degrees around X axis)
            map3D.transform.rotation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
            
            // Position with manual offset to align with 2D map
            // X: 3.7cm right, Y: 1.5cm up, Z: 1.8cm forward/down
            map3D.position = [0.037, 0.015, -0.018]
            
            // Optional: Add a slight transparency to see both maps
            // map3D.opacity = 0.8
            
            return map3D
        } catch {
            print("Failed to load 3D map: \(error)")
            return nil
        }
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
            
            // Add interaction components for hover and tap
            // Use .all to allow both direct and indirect input
            barEntity.components.set(InputTargetComponent(allowedInputTypes: .all))
            barEntity.components.set(HoverEffectComponent())
            
            // Add collision component - will be updated with actual size later
            let collisionShape = ShapeResource.generateBox(size: [0.01, 0.05, 0.01])
            barEntity.components.set(CollisionComponent(shapes: [collisionShape], isStatic: true))
            
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
        // Store current year data for info boxes
        currentYearData = yearData
        
        let bins = DataLoader.shared.bins
        
        print("MapScene: Updating bars with \(yearData.count) year data entries")

        
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
                
                // Update collision shape to match bar size
                let collisionShape = ShapeResource.generateBox(size: [0.01, height, 0.01])
                barEntity.components.set(CollisionComponent(shapes: [collisionShape], isStatic: true))
                
                // Update color
                if var material = barEntity.model?.materials.first as? UnlitMaterial {
                    material.color = .init(tint: UIColor(color))
                    barEntity.model?.materials = [material]
                }
                
                // Make visible
                barEntity.isEnabled = true
                
            } else {
                // No cases - hide bar completely
                barEntity.scale = [0, 0, 0]  // Completely hide
                barEntity.position.y = 0.01
                barEntity.isEnabled = false
            }
        }
    }
    
    private func updateBarsForYear(_ year: Int) async {
        // Hide info box when year changes
        if let infoBox = infoBoxEntity {
            infoBox.removeFromParent()
            infoBoxEntity = nil
        }
        
        // Reset selected bar color before changing year
        if let previousCode = selectedCountryCode, 
           let previousBar = barEntities[previousCode],
           let previousData = currentYearData[previousCode] {
            // Restore original color
            let bin = DataLoader.shared.bins[safe: previousData.bin]
            let originalColor = bin?.color ?? .gray
            if var material = previousBar.model?.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor(originalColor))
                previousBar.model?.materials = [material]
            }
        }
        
        selectedCountryCode = nil
        
        do {
            let yearData = try await DataLoader.shared.loadYear(year)
            currentYearData = yearData
            
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
        
        // Store current X and Z positions (these should never change)
        let currentX = barEntity.position.x
        let currentZ = barEntity.position.z
        
        // Cancel any existing animations on this entity
        barEntity.stopAllAnimations()
        
        // Check if we need to hide the bar completely
        if yearData == nil || yearData?.bin == 0 {
            // No data - animate to invisible
            let targetTransform = Transform(
                scale: [0, 0, 0],  // Completely hide
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                translation: [currentX, 0.01, currentZ]
            )
            barEntity.move(to: targetTransform, relativeTo: nil, duration: TimeInterval(duration))
            barEntity.isEnabled = false
        } else {
            // Has data - animate to proper height
            let scaleY = targetHeight / 0.005
            let targetY = 0.01 + (targetHeight / 2)
            
            let targetTransform = Transform(
                scale: [2, scaleY, 2],  // X and Z scaled by 2 for 10mm bars
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                translation: [currentX, targetY, currentZ]
            )
            barEntity.move(to: targetTransform, relativeTo: nil, duration: TimeInterval(duration))
            barEntity.isEnabled = true
        }
        
        // Update color
        if var material = barEntity.model?.materials.first as? UnlitMaterial {
            material.color = .init(tint: UIColor(targetColor))
            barEntity.model?.materials = [material]
        }
    }
    
    // MARK: - Interaction Methods (Updated)
    
    private func createInfoBox(for country: Country, cases: Int, position: SIMD3<Float>) -> Entity {
        let container = Entity()
        container.name = "InfoBox"
        
        // Create background panel with rounded corners - bigger size with more padding
        let panelWidth: Float = 0.20
        let panelHeight: Float = 0.075
        // Use generatePlane with corner radius for better control
        print("Creating info box plane with dimensions: \(panelWidth) x \(panelHeight)")
        let panelMesh = MeshResource.generatePlane(
            width: panelWidth, 
            height: panelHeight,
            cornerRadius: 0.025  // 25mm corner radius
        )
        
        // Create glass-like material with darker background to match main window
        var panelMaterial = SimpleMaterial()
        panelMaterial.color = .init(tint: UIColor(white: 0.15, alpha: 0.85))
        panelMaterial.roughness = .init(floatLiteral: 0.3)
        panelMaterial.metallic = .init(floatLiteral: 0.0)
        
        let panel = ModelEntity(mesh: panelMesh, materials: [panelMaterial])
        // Ensure the panel has input and collision components for stability
        panel.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        panel.generateCollisionShapes(recursive: false)
        container.addChild(panel)
        
        // Add a blue border to match the selected bar
        let borderMesh = MeshResource.generatePlane(
            width: panelWidth + 0.002, 
            height: panelHeight + 0.002,
            cornerRadius: 0.026
        )
        var borderMaterial = UnlitMaterial()
        borderMaterial.color = .init(tint: UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 0.3))
        let border = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
        border.position.z = -0.002
        container.addChild(border)
        
        // Create country name text - bigger and bolder
        var fontSize: CGFloat = 0.018
        let maxTextWidth = panelWidth * 0.75  // Allow text to use 75% of panel width
        
        // Try different font sizes until the text fits
        var countryMesh: MeshResource
        var textBounds: BoundingBox
        
        repeat {
            countryMesh = MeshResource.generateText(
                country.name,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: fontSize, weight: .semibold)
            )
            
            // Create temporary entity to measure bounds
            let tempEntity = ModelEntity(mesh: countryMesh)
            textBounds = tempEntity.model?.mesh.bounds ?? BoundingBox()
            let textWidth = textBounds.max.x - textBounds.min.x
            
            if textWidth > maxTextWidth && fontSize > 0.010 {
                fontSize -= 0.002  // Reduce font size
                print("Text too wide (\(textWidth) > \(maxTextWidth)), reducing font size to \(fontSize)")
            } else {
                break
            }
        } while fontSize > 0.010  // Minimum font size
        
        if fontSize < 0.018 {
            print("Scaled '\(country.name)' from 0.018 to \(fontSize) to fit in panel")
        }
        
        var textMaterial = UnlitMaterial()
        textMaterial.color = .init(tint: .white)
        
        let countryText = ModelEntity(mesh: countryMesh, materials: [textMaterial])
        // Center the text horizontally based on its actual width
        let textWidth = textBounds.max.x - textBounds.min.x
        countryText.position = [-textWidth / 2, panelHeight * 0.10, 0.001]
        container.addChild(countryText)
        
        // Create cases text with formatting - slightly bigger
        let casesString = cases == 1 ? "1 case" : "\(cases.formatted()) cases"
        let casesMesh = MeshResource.generateText(
            casesString,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.014, weight: .regular)
        )
        
        var casesMaterial = UnlitMaterial()
        casesMaterial.color = .init(tint: UIColor(white: 0.85, alpha: 1.0))
        
        let casesText = ModelEntity(mesh: casesMesh, materials: [casesMaterial])
        // Center the cases text as well
        let casesEntity = ModelEntity(mesh: casesMesh)
        let casesBounds = casesEntity.model?.mesh.bounds ?? BoundingBox()
        let casesWidth = casesBounds.max.x - casesBounds.min.x
        casesText.position = [-casesWidth / 2, -panelHeight * 0.18, 0.001]
        container.addChild(casesText)
        
        // Position the info box
        container.position = position
        
        return container
    }
    
    private func handleBarTap(countryCode: String) {
        guard let country = DataLoader.shared.countries[countryCode],
              let yearData = currentYearData[countryCode],
              let barEntity = barEntities[countryCode] else { return }
        
        // Remove previous info box if it exists
        if let oldInfoBox = infoBoxEntity {
            oldInfoBox.removeFromParent()
            infoBoxEntity = nil
        }
        
        // Reset previous selected bar color
        if let previousCode = selectedCountryCode, 
           let previousBar = barEntities[previousCode],
           let previousData = currentYearData[previousCode] {
            // Restore original color
            let bin = DataLoader.shared.bins[safe: previousData.bin]
            let originalColor = bin?.color ?? .gray
            if var material = previousBar.model?.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor(originalColor))
                previousBar.model?.materials = [material]
            }
        }
        
        // Hide info box if tapping the same bar
        if selectedCountryCode == countryCode {
            selectedCountryCode = nil
            return
        }
        
        // Create and show new info box
        selectedCountryCode = countryCode
        
        // Change selected bar color to bright blue
        if var material = barEntity.model?.materials.first as? UnlitMaterial {
            material.color = .init(tint: UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0))
            barEntity.model?.materials = [material]
        }
        
        // Calculate position relative to the bar
        let barHeight = barEntity.scale.y * 0.005 // Actual height of the bar
        
        // Calculate world position for the info box
        let worldPos = SIMD3<Float>(
            barEntity.position.x,
            barEntity.position.y + barHeight / 2 + 0.08,
            barEntity.position.z
        )
        
        // Get actual case count
        let actualCases = DataLoader.shared.getActualCases(for: countryCode, year: currentYear) ?? 0
        
        // Create the info box entity with the calculated position
        let infoBox = createInfoBox(for: country, cases: actualCases, position: worldPos)
        
        // Add to the same parent as the bars (barsRoot)
        if let barsRoot = barsRoot {
            barsRoot.addChild(infoBox)
            infoBoxEntity = infoBox
            
            // Add smooth entrance animation
            // Start from small scale and animate to full size
            infoBox.scale = [0.001, 0.001, 0.001]
            let targetTransform = Transform(
                scale: [1, 1, 1],
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                translation: worldPos
            )
            infoBox.move(to: targetTransform, relativeTo: infoBox.parent, duration: 0.15)
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
