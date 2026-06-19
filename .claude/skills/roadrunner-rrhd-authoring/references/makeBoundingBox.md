# Skill: makeBoundingBox

**Package:** `rrhd_authoring.utils`
**Function:** `bbox = rrhd_authoring.utils.makeBoundingBox(center, dimension, geoOrientation)`
**Source:** `+rrhd_authoring/+utils/makeBoundingBox.m`

## Description
Creates a `GeoOrientedBoundingBox` for placed objects (signs, signals, static objects, stencil markings).

## Inputs
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `center` | [1x3] double | (required) | [x, y, z] position in ENU meters |
| `dimension` | [1x3] double | (required) | [halfLength, halfWidth, halfHeight] in meters |
| `geoOrientation` | [1x3] double | `[0 0 0]` | [roll, pitch, heading] in radians |

## Output
`bbox` — `roadrunner.hdmap.GeoOrientedBoundingBox`.

## Implementation
```matlab
bbox = roadrunner.hdmap.GeoOrientedBoundingBox( ...
    Center=center, ...
    Dimension=dimension, ...
    GeoOrientation=geoOrientation);
```

## Example
```matlab
bbox = rrhd_authoring.utils.makeBoundingBox([10 5 0], [1 0.5 2], [0 0 pi/4]);
```

----

Copyright 2026 The MathWorks, Inc.
