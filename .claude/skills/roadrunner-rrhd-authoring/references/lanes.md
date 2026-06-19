# Skill: lanes

**Package:** `rrhd_authoring.build`
**Function:** `laneArray = rrhd_authoring.build.lanes(specs)`
**Source:** `+rrhd_authoring/+build/lanes.m`

## Description
Creates `roadrunner.hdmap.Lane` objects from spec structs. Handles boundary linking, predecessor/successor wiring, speed limit and signal parametric attributions, and metadata.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique lane ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Centerline in ENU meters |
| `.travelDirection` | string | Yes | `"Forward"` / `"Backward"` / `"Bidirectional"` / `"Undirected"` |
| `.laneType` | string | Yes | `"Driving"` / `"Shoulder"` / `"Curb"` / `"Sidewalk"` / `"Biking"` / `"Parking"` / `"Border"` / `"Restricted"` / `"CenterTurn"` / `"Entry"` / `"Exit"` / `"OffRamp"` / `"OnRamp"` / `"Stop"` / `"Median"` / `"None"` |
| `.leftBoundaryID` | string | Yes | ID of left LaneBoundary |
| `.leftAlignment` | string | Yes | `"Forward"` / `"Backward"` |
| `.rightBoundaryID` | string | Yes | ID of right LaneBoundary |
| `.rightAlignment` | string | Yes | `"Forward"` / `"Backward"` |
| `.predecessors` | struct array | No | Each with `.id` (string), `.alignment` (string) |
| `.successors` | struct array | No | Each with `.id` (string), `.alignment` (string) |
| `.speedLimits` | struct array | No | Each with `.speedLimitID` (string), `.span` ([start end]) |
| `.signalRefs` | struct array | No | Each with `.signalID` (string), `.span` ([start end]) |
| `.metadata` | struct array | No | Each with `.name` (string), `.value` (string) |

## Output
`laneArray` — column vector of `roadrunner.hdmap.Lane` objects.

## Implementation Detail — Boundary Linking
> **Gotcha:** Lane boundary properties (`LeftLaneBoundary`, `RightLaneBoundary`) and
> topology properties (`Predecessors`, `Successors`) are `AlignedReference` objects.
> You must create a full `AlignedReference` then assign — never dot-assign into the empty default.

```matlab
% Correct pattern for setting a lane's left boundary:
ref = roadrunner.hdmap.Reference;
ref.ID = "LB_Center";
ar = roadrunner.hdmap.AlignedReference;
ar.Reference = ref;
ar.Alignment = "Forward";
ln.LeftLaneBoundary = ar;

% Correct pattern for appending successors:
succs = roadrunner.hdmap.AlignedReference.empty;
ref = roadrunner.hdmap.Reference;
ref.ID = "Lane_Next";
ar = roadrunner.hdmap.AlignedReference;
ar.Reference = ref;
ar.Alignment = "Forward";
succs(end+1) = ar;
ln.Successors = succs(:);
```

## Example
```matlab
specs(1).id = "Lane_EB";
specs(1).geometry = [0 -1.75 0; 100 -1.75 0];
specs(1).travelDirection = "Forward";
specs(1).laneType = "Driving";
specs(1).leftBoundaryID = "LB_Center";
specs(1).leftAlignment = "Forward";
specs(1).rightBoundaryID = "LB_Right";
specs(1).rightAlignment = "Forward";
specs(1).successors(1).id = "Lane_EB_2";
specs(1).successors(1).alignment = "Forward";

lns = rrhd_authoring.build.lanes(specs);
```

----

Copyright 2026 The MathWorks, Inc.
