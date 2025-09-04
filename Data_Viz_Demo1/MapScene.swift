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
    
    // Cached materials for each color to avoid recreating
    @State private var materialCache: [Color: UnlitMaterial] = [:]
    
    // Interaction states
    @State private var hoveredCountryCode: String?
    @State private var selectedCountryCode: String?
    @State private var currentYearData: [String: YearData] = [:]
    @State private var infoBoxEntity: Entity?
    
    // Debouncing for year changes to prevent memory crashes
    @State private var loadingTask: Task<Void, Never>?
    
    // Rate-limited real-time updates
    @State private var lastUpdateTime = Date()
    @State private var isRateLimited = false
    
    // Map dimensions in meters
    private let mapWidth: Float = 1.2
    private let mapHeight: Float = 0.6
    
    // 3D map entity
    @State private var map3DEntity: Entity?
    
    // World anchor that can be updated
    @State private var worldAnchor: AnchorEntity?
    

    

    
    var body: some View {
        RealityView { content, attachments in
            // Create world anchor at table height, closer to window
            let anchor = AnchorEntity(world: [0, 0.9, -1.2])
            content.add(anchor)
            worldAnchor = anchor
            
            // Create map rig (parent for all map elements)
            let rig = Entity()
            rig.name = "MapRig"
            anchor.addChild(rig)
            mapRig = rig
            


            
            // Create map plane - COMMENTED OUT TO HIDE 2D MAP
            // if let mapEntity = await createMapPlane() {
            //     rig.addChild(mapEntity)
            // }
            
            // Add 3D map
            if let map3D = await create3DMap() {
                rig.addChild(map3D)
                map3DEntity = map3D
            }
            
            // Add directional light for 3D map
            let directionalLight = DirectionalLight()
            directionalLight.light.intensity = 10000  // Cranked up brightness
            directionalLight.look(at: [0, 0, 0], from: [1, 1, 1], relativeTo: nil)
            rig.addChild(directionalLight)
            
            // Create bars root entity
            let barsContainer = Entity()
            barsContainer.name = "BarsRoot"
            rig.addChild(barsContainer)
            barsRoot = barsContainer
            
            // Add timeline menu attachment in 3D space
            if let timelineAttachment = attachments.entity(for: "timeline") {
                timelineAttachment.position = [0, -0.05, 0.3]  // Moved closer to match map at -1.2
                anchor.addChild(timelineAttachment)
            }
            
            // Load data and create bars
            await loadDataAndCreateBars()
            

        } attachments: {
            Attachment(id: "timeline") {
                ControlPanel(currentYear: $currentYear) { year in
                    NotificationCenter.default.post(
                        name: .yearChanged,
                        object: nil,
                        userInfo: ["year": year]
                    )
                }
                .scaleEffect(0.8)  // Good size for 3D space
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
                .allowsHitTesting(true)  // Ensure touch input works in 3D
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .yearChanged)) { notification in
            if let year = notification.userInfo?["year"] as? Int {
                currentYear = year
                
                let now = Date()
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
                
                // Rate limit: minimum 100ms between updates
                if timeSinceLastUpdate >= 0.1 && !isRateLimited {
                    // Immediate update with fast animation
                    lastUpdateTime = now
                    isRateLimited = true
                    
                    // Cancel any pending slow updates
                    loadingTask?.cancel()
                    
                    // Fast real-time update
                    Task {
                        await updateBarsForYear(year, fastMode: true)
                        
                        // Reset rate limiting after update completes
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                        isRateLimited = false
                    }
                } else {
                    // Too fast - use debounced update
                    loadingTask?.cancel()
                    loadingTask = Task {
                        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce
                        guard !Task.isCancelled else { return }
                        await updateBarsForYear(year, fastMode: false)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetMapPosition)) { _ in
            resetMapPosition()
        }
        .onDisappear {
            // Cancel any pending loading task to prevent memory leaks
            loadingTask?.cancel()
        }

        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Only process bar entities - ignore map plane and other entities
                    if value.entity.name.hasPrefix("Bar_") {
                        let countryCode = String(value.entity.name.dropFirst(4))
                        handleBarTap(countryCode: countryCode)
                    }
                    // All other entities (including map plane) are ignored
                }
        )




    }
    
    
    // MARK: - Map Positioning
    
    private func resetMapPosition() {
        guard let rig = mapRig else { return }
        
        // Use the proper visionOS API to reset position
        // Only modify position, not scale or rotation
        Task { @MainActor in
            rig.position = .zero
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
        
        // Map collision disabled - only bars need collision for interaction
        // mapEntity.generateCollisionShapes(recursive: false)
        
        return mapEntity
    }
    

    
    // MARK: - 3D Map Creation
    
    private func create3DMap() async -> Entity? {
        do {
            // Load the 3D map model from RealityKitContent
            let map3D = try await Entity(named: "WorldMap3D", in: realityKitContentBundle)
            map3D.name = "Map3D"
            
            // Simple scaling - 10% bigger (0.2112 instead of 0.192)
            map3D.scale = [0.2112, 0.2112, 0.2112]
            
            // No rotation - keep it in default orientation
            // map3D.transform.rotation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
            
            // Position to align with the 2D map (moved up by 0.03)
            map3D.position = [0, 0, 0]  // Was -0.03, now 0
            
            // Optional: Add a slight transparency to see both maps
            // map3D.opacity = 0.8
            
            // Make sure the 3D map doesn't block interactions with bars
            // Remove any collision components that might interfere
            map3D.components.remove(CollisionComponent.self)
            map3D.components.remove(InputTargetComponent.self)
            
            // Recursively remove collision/input from all children
            map3D.children.forEach { child in
                child.components.remove(CollisionComponent.self)
                child.components.remove(InputTargetComponent.self)
            }
            
            return map3D
        } catch {
            print("MapScene: Failed to load 3D map: \(error)")
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
                
                // Update collision shape to match visual bar exactly when stopped
                let collisionWidth: Float = 0.01  // Same as visual bar (1cm)
                let collisionShape = ShapeResource.generateBox(size: [collisionWidth, height, collisionWidth])
                
                // Offset collision box down by half height to align with visual bar base
                let collisionOffset = SIMD3<Float>(0, -height/2, 0)
                barEntity.components.set(CollisionComponent(
                    shapes: [collisionShape.offsetBy(translation: collisionOffset)], 
                    isStatic: true
                ))
                
                // Update color using cached material
                if materialCache[color] == nil {
                    var newMaterial = UnlitMaterial()
                    newMaterial.color = .init(tint: UIColor(color))
                    materialCache[color] = newMaterial
                }
                
                if let cachedMaterial = materialCache[color] {
                    barEntity.model?.materials = [cachedMaterial]
                }
                
                // Make visible
                barEntity.isEnabled = true
                
            } else {
                // No cases - hide bar completely and remove collision
                barEntity.scale = [0, 0, 0]  // Completely hide
                barEntity.position.y = 0.01
                barEntity.isEnabled = false
                
                // Remove collision component - hidden bars shouldn't block interactions
                barEntity.components.remove(CollisionComponent.self)
            }
        }
    }
    
    private func updateBarsForYear(_ year: Int, fastMode: Bool = false) async {
        // Check if we're still on the requested year (user might have moved on)
        guard currentYear == year else { return }
        
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
            
            // Double-check we're still on the requested year
            guard currentYear == year else { return }
            
            currentYearData = yearData
            
            // Use simpler, non-animated updates during rapid changes
            let shouldAnimate = !Task.isCancelled
            
            if shouldAnimate {
                if fastMode {
                    // Fast mode: Quick animation without wave, shorter duration
                    await withTaskGroup(of: Void.self) { group in
                        for (code, barEntity) in barEntities {
                            group.addTask {
                                await self.animateBarUpdate(
                                    barEntity: barEntity,
                                    yearData: yearData[code],
                                    duration: 0.2  // Fast 200ms animation
                                )
                            }
                        }
                    }
                } else {
                    // Normal mode: Beautiful geographic wave animation
                    await withTaskGroup(of: Void.self) { group in
                        for (code, barEntity) in barEntities {
                            group.addTask {
                                // Get longitude for wave delay (0.0 = West, 1.0 = East)
                                let longitude = DataLoader.shared.centroids[code]?.x ?? 0.5
                                let waveDelay = longitude * 0.2  // 0-200ms stagger
                                
                                // Small delay before animation
                                try? await Task.sleep(nanoseconds: UInt64(waveDelay * 1_000_000_000))
                                guard !Task.isCancelled else { return }
                                
                                await self.animateBarUpdate(
                                    barEntity: barEntity,
                                    yearData: yearData[code],
                                    duration: 0.5  // Normal 500ms animation
                                )
                            }
                        }
                    }
                }
            } else {
                // Quick update without animation
                updateBars(with: yearData)
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
            barEntity.move(to: targetTransform, relativeTo: barEntity.parent, duration: TimeInterval(duration))
            barEntity.isEnabled = false
            
            // Remove collision component during animation to reduce physics calculations
            barEntity.components.remove(CollisionComponent.self)
        } else {
            // Has data - animate to proper height
            let scaleY = targetHeight / 0.005
            let targetY = 0.01 + (targetHeight / 2)
            
            let targetTransform = Transform(
                scale: [2, scaleY, 2],  // X and Z scaled by 2 for 10mm bars
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                translation: [currentX, targetY, currentZ]
            )
            barEntity.move(to: targetTransform, relativeTo: barEntity.parent, duration: TimeInterval(duration))
            barEntity.isEnabled = true
        }
        
        // Update color using cached material
        if materialCache[targetColor] == nil {
            var newMaterial = UnlitMaterial()
            newMaterial.color = .init(tint: UIColor(targetColor))
            materialCache[targetColor] = newMaterial
        }
        
        if let cachedMaterial = materialCache[targetColor] {
            barEntity.model?.materials = [cachedMaterial]
        }
        
        // Update collision shape after animation completes to match visual bar exactly
        if yearData != nil && yearData?.bin != 0 {
            // Wait for animation to complete, then update collision
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            // Set collision to match final visual bar size
            let collisionWidth: Float = 0.01  // Same as visual bar (1cm)
            let collisionShape = ShapeResource.generateBox(size: [collisionWidth, targetHeight, collisionWidth])
            
            // Offset collision box down by half height to align with visual bar base
            let collisionOffset = SIMD3<Float>(0, -targetHeight/2, 0)
            barEntity.components.set(CollisionComponent(
                shapes: [collisionShape.offsetBy(translation: collisionOffset)], 
                isStatic: true
            ))
        }
    }
    
    // MARK: - Interaction Methods (Updated)
    
    private func createInfoBox(for country: Country, cases: Int, position: SIMD3<Float>) -> Entity {
        let container = Entity()
        container.name = "InfoBox"
        
        // Create background panel with minimal rounding to match ornaments
        let panelWidth: Float = 0.20
        let panelHeight: Float = 0.075
        let cornerRadius: Float = 0.016  // Reduced from 0.025 to match ornaments
        
        let panelMesh = MeshResource.generatePlane(
            width: panelWidth, 
            height: panelHeight,
            cornerRadius: cornerRadius
        )
        
        // Use simple dark glass-like material (RealityKit can't use SwiftUI .thickMaterial)
        var glassMaterial = SimpleMaterial()
        glassMaterial.color = .init(tint: UIColor.black.withAlphaComponent(0.7))
        glassMaterial.roughness = .init(floatLiteral: 0.2)
        glassMaterial.metallic = .init(floatLiteral: 0.0)
        
        let panel = ModelEntity(mesh: panelMesh, materials: [glassMaterial])
        panel.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        panel.generateCollisionShapes(recursive: false)
        
        container.addChild(panel)
        
        // Add thin white semi-transparent outline to match ornament style
        let borderMesh = MeshResource.generatePlane(
            width: panelWidth + 0.002, 
            height: panelHeight + 0.002,
            cornerRadius: cornerRadius + 0.001
        )
        var borderMaterial = UnlitMaterial()
        borderMaterial.color = .init(tint: UIColor.white.withAlphaComponent(0.25))
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



// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
