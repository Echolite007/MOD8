# Skill: curveMarkings

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.curveMarkings(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/curveMarkings.m`

## Description
Creates `roadrunner.hdmap.CurveMarkingType` definitions and `roadrunner.hdmap.CurveMarking` instances. Curve markings follow a polyline path with optional flip/reverse. Uses `MarkingTypeReference` property (not `CurveMarkingTypeReference`).

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique curve marking type ID |
| `.assetPath` | string | Yes | Relative path to marking asset |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique instance ID |
| `.curveMarkingTypeID` | string | Yes | Reference to a CurveMarkingType ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Polyline path in ENU meters |
| `.flip` | logical | No | Flip side-to-side (default false) |
| `.reverse` | logical | No | Draw end-to-start (default false) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.CurveMarkingType`
- `instanceArray` — column vector of `roadrunner.hdmap.CurveMarking`

## Example
```matlab
ts.id = "EdgeLine"; ts.assetPath = "Assets/Markings/SolidSingleWhite.rrlms";
is.id = "CM_1"; is.curveMarkingTypeID = "EdgeLine";
is.geometry = [0 5 0; 50 5.5 0; 100 5 0];
[cmTypes, cmInstances] = rrhd_authoring.build.curveMarkings(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
