# Skill: laneBoundaries

**Package:** `rrhd_authoring.build`
**Function:** `lbArray = rrhd_authoring.build.laneBoundaries(specs)`
**Source:** `+rrhd_authoring/+build/laneBoundaries.m`

## Description
Creates `roadrunner.hdmap.LaneBoundary` objects with optional lane marking parametric attributions.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique boundary ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Polyline coordinates in ENU meters |
| `.markings` | struct array | No | Each with `.markingID` (string), `.span` ([start end] in [0,1]), `.flipLaterally` (logical) |

## Output
`lbArray` — column vector of `roadrunner.hdmap.LaneBoundary` objects.

## Example
```matlab
specs(1).id = "LB_Left";
specs(1).geometry = [0 3.5 0; 100 3.5 0];
specs(1).markings(1).markingID = "SolidWhite";
specs(1).markings(1).span = [0 1];
specs(1).markings(1).flipLaterally = false;

lbs = rrhd_authoring.build.laneBoundaries(specs);
```

----

Copyright 2026 The MathWorks, Inc.
