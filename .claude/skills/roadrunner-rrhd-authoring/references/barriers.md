# Skill: barriers

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.barriers(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/barriers.m`

## Description
Creates `roadrunner.hdmap.BarrierType` definitions and `roadrunner.hdmap.Barrier` instances. Barriers use polyline geometry with extrusion along the path.

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique barrier type ID |
| `.extrusionPath` | string | Yes | Relative path to extrusion asset (`.rrext`) |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique barrier instance ID |
| `.barrierTypeID` | string | Yes | Reference to a BarrierType ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Polyline base path in ENU meters |
| `.flipLaterally` | logical | No | Flip extrusion side (default false) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.BarrierType`
- `instanceArray` — column vector of `roadrunner.hdmap.Barrier`

## Example
```matlab
ts.id = "GuardRailType"; ts.extrusionPath = "Assets/Barriers/GuardRail.rrext";
is.id = "GR_1"; is.barrierTypeID = "GuardRailType";
is.geometry = [0 5 0; 50 5 0; 100 5 0];
[barTypes, barInstances] = rrhd_authoring.build.barriers(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
