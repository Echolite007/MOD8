# Barrier & Extrusion Asset Mapping

Maps barrier/guardrail/fence types to RoadRunner extrusion assets.

## Unified Barrier Table

| Source Type | Source Format | Asset Path |
|---|---|---|
| `guardrail` / `guard_rail` | Lanelet2, OpenDRIVE, Apollo | `Extrusions/GuardRail.rrext` |
| `GUARDRAIL` | HERE, TomTom | `Extrusions/GuardRail.rrext` |
| `barrier` / `jersey_barrier` | Lanelet2, Apollo | `Extrusions/JerseyBarrier.rrext` |
| `JERSEY_BARRIER` / `BARRIER_JERSEY` | HERE, TomTom | `Extrusions/JerseyBarrier.rrext` |
| `fence` | Lanelet2 | `Extrusions/Fence.rrext` |
| `FENCE` | HERE, TomTom | `Extrusions/Fence.rrext` |
| `wall` | Lanelet2 | `Extrusions/HighwayBorderwall01.rrext` |
| `WALL` | HERE | `Extrusions/HighwayBorderwall02.rrext` |
| `WALL_SHORT` | HERE | `Extrusions/HighwayBorderwall03.rrext` |
| `railing` | Lanelet2 | `Extrusions/BridgeRailing.rrext` |
| `concrete_barrier` | OpenDRIVE (name) | `Extrusions/FShapeBarrier.rrext` |

## Additional Barrier-like Props (OpenDRIVE objects)

| Object Type | Asset Path |
|---|---|
| `barrier` (barricade) | `Props/TrafficControl/Barricade01.fbx` |
| `barrier` (barricade alt) | `Props/TrafficControl/Barricade02.fbx` |
| `barrier` (drum) | `Props/TrafficControl/Drum01.fbx` |
| `barrier` (F-barrier) | `Props/TrafficControl/F_Barrier01.fbx` |
| `barrier` (chevron) | `Props/TrafficControl/ChevronSign01.fbx` |
| `barrier` (arrow board) | `Props/TrafficControl/ArrowBoard01.fbx` |
| `barrier` (sandbag) | `Props/FreewayTrusses/Sandbag01.fbx` |

## MATLAB Construction Pattern

```matlab
% BarrierType (defines the extrusion asset)
bt = roadrunner.hdmap.BarrierType;
bt.ID = "GuardRail";
rap = roadrunner.hdmap.RelativeAssetPath;
rap.AssetPath = "Assets/Extrusions/GuardRail.rrext.rrmeta";
bt.ExtrusionPath = rap;

% Barrier instance (geometry + type reference)
b = roadrunner.hdmap.Barrier;
b.ID = "Barrier_GuardRail_1";
b.Geometry = wayGeometry;  % Nx3 polyline
typeRef = roadrunner.hdmap.Reference;
typeRef.ID = "GuardRail";
b.BarrierTypeReference = typeRef;
b.FlipLaterally = false;
```

## Notes

- `.rrext` and `.rrext.rrmeta` both work — the `.rrmeta` suffix is the metadata wrapper
- Barriers follow polyline geometry (Nx3), not bounding boxes
- `FlipLaterally` controls which side the barrier faces (relevant for asymmetric shapes like F-barriers)

----

Copyright 2026 The MathWorks, Inc.
