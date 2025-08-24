# Coordinate System Notes

## Key Learnings from Development

### 1. Natural Earth Label Points vs Centroids
- Use `LABEL_X` and `LABEL_Y` from Natural Earth shapefiles, not geometric centroids
- Label points are specifically designed for map visualization and avoid oceans/borders
- These give more intuitive positions (e.g., USA at visual center, not including Alaska)

### 2. Coordinate Transformation
When converting from normalized coordinates (0-1) to RealityKit world space:

```swift
// Correct transformation (no Y inversion needed):
let localX = (normalizedPos.x - 0.5) * mapWidth
let localZ = (normalizedPos.y - 0.5) * mapHeight
```

### 3. RealityKit Plane Rotation
- Plane is generated in XY plane initially
- Rotated -90° around X axis to lie flat in XZ plane
- Texture coordinates map directly - no flipping required
- Y coordinate becomes Z coordinate after rotation

### 4. Equirectangular Projection
Our normalized coordinates use standard equirectangular projection:
- x_norm = (longitude + 180) / 360
- y_norm = (90 - latitude) / 180
- (0,0) = Northwest corner (-180°, 90°)
- (1,1) = Southeast corner (180°, -90°)

### 5. Entity Hierarchy
Important: Bars should be children of the map rig, NOT the rotated map plane:
```
WorldAnchor → MapRig → MapPlane (rotated)
                    → BarsRoot → Individual bars
```
This prevents bars from inheriting the plane's rotation.

### 6. Debugging Tips
When debugging coordinate issues:
1. Add visual markers at known positions (corners, center)
2. Test with easily identifiable countries (Brazil, Australia, UK)
3. Compare with reference maps (Our World in Data)
4. Check both data flow AND visual representation
