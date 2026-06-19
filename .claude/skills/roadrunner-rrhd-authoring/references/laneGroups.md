# Skill: laneGroups

**Package:** `rrhd_authoring.build`
**Function:** `lgArray = rrhd_authoring.build.laneGroups(specs)`
**Source:** `+rrhd_authoring/+build/laneGroups.m`

## Description
Creates `roadrunner.hdmap.LaneGroup` objects with ordered lane references and optional CRG surface references.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique lane group ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Approximate road centerline in ENU |
| `.lanes` | struct array | Yes | Ordered left-to-right, each with `.id` (string), `.alignment` (`"Forward"` / `"Backward"`) |
| `.crgRefs` | struct array | No | Each with `.crgDefID` (string), `.sStart` (double), `.sEnd` (double) |

## Output
`lgArray` — column vector of `roadrunner.hdmap.LaneGroup` objects.

## Example
```matlab
specs.id = "LG_Main";
specs.geometry = [0 0 0; 100 0 0];
specs.lanes(1) = struct('id',"Lane_WB", 'alignment',"Backward");
specs.lanes(2) = struct('id',"Lane_EB", 'alignment',"Forward");
lgs = rrhd_authoring.build.laneGroups(specs);
```

----

Copyright 2026 The MathWorks, Inc.
