# Skill: signs

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.signs(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/signs.m`

## Description
Creates `roadrunner.hdmap.SignType` definitions and `roadrunner.hdmap.Sign` instances using the RRHD type+instance pattern with `GeoOrientedBoundingBox` placement.

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique sign type ID |
| `.assetPath` | string | Yes | Relative path to sign asset (`.svg`, `.svg_rrx`, or `.fbx`) |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique sign instance ID |
| `.signTypeID` | string | Yes | Reference to a SignType ID |
| `.center` | [x y z] | Yes | Position in ENU meters |
| `.dimension` | [dx dy dz] | Yes | Full extents in meters (width, height, depth) |
| `.geoOrientation` | [heading pitch roll] | No | Degrees (default [0 0 0]) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.SignType`
- `instanceArray` — column vector of `roadrunner.hdmap.Sign`

## Example
```matlab
ts.id = "StopSignType"; ts.assetPath = "Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg";
is.id = "Stop_1"; is.signTypeID = "StopSignType";
is.center = [50 -5 1.5]; is.dimension = [0 0.6 0.6];
is.geoOrientation = [90 0 0];  % [heading, pitch, roll] in degrees
[signTypes, signInstances] = rrhd_authoring.build.signs(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
