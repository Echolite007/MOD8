# Skill: junctions

**Package:** `rrhd_authoring.build`
**Function:** `jArray = rrhd_authoring.build.junctions(specs)`
**Source:** `+rrhd_authoring/+build/junctions.m`

## Description
Creates `roadrunner.hdmap.Junction` objects with MultiPolygon geometry, lane references, and optional signal configurations with phases.

> **Note:** RoadRunner's `buildScene` with `DetectAsphaltSurfaces=true` auto-detects junctions where roads overlap. Explicit Junction objects are optional and mainly used for signal phase configuration.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique junction ID |
| `.laneIDs` | string array | Yes | IDs of lanes enclosed in this junction |
| `.polygons` | struct array | No | Each with `.exteriorRing` (Mx3 double, closed polygon), `.interiorRings` (cell of Px3 double, holes) |
| `.configurations` | struct array | No | Each with `.id`, `.name`, `.phases` (struct array with `.id`, `.name`, `.time` (int32), `.laneStates` (struct array with `.laneID`, `.state`)) |

### Junction Lane States
- `"GoAlways"` / `"Yield"` / `"Stop"` / `"Stop/Yield"`

## Output
`jArray` — column vector of `roadrunner.hdmap.Junction` objects.

## Example
```matlab
specs.id = "Junc_Main";
specs.laneIDs = ["JLane_1","JLane_2","JLane_3"];
specs.polygons(1).exteriorRing = [-10 -10 0; 10 -10 0; 10 10 0; -10 10 0; -10 -10 0];
juncs = rrhd_authoring.build.junctions(specs);
```

----

Copyright 2026 The MathWorks, Inc.
