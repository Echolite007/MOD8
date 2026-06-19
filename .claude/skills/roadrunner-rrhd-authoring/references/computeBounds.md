# Skill: computeBounds

**Package:** `rrhd_authoring.utils`
**Function:** `bounds = rrhd_authoring.utils.computeBounds(rrMap)`
**Source:** `+rrhd_authoring/+utils/computeBounds.m`

## Description
Computes `GeographicBoundary` from all geometry in an RRHD map. Scans Lanes, LaneBoundaries, Barriers, CurveMarkings (polylines), and Signs, Signals, StaticObjects, StencilMarkings (bounding boxes).

## Inputs
| Parameter | Type | Description |
|-----------|------|-------------|
| `rrMap` | roadrunnerHDMap | The HD map object |

## Output
`bounds` — 2x3 double `[minX minY minZ; maxX maxY maxZ]`.

## Algorithm
1. Collect all polyline geometry points from Lanes, LaneBoundaries, Barriers, CurveMarkings
2. Collect bounding box extents (center +/- dimension) from Signs, Signals, StaticObjects, StencilMarkings
3. Return `[min(allPts); max(allPts)]`

## Example
```matlab
rrMap.GeographicBoundary = rrhd_authoring.utils.computeBounds(rrMap);
```

----

Copyright 2026 The MathWorks, Inc.
