# Skill: stencilMarkings

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.stencilMarkings(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/stencilMarkings.m`

## Description
Creates `roadrunner.hdmap.StencilMarkingType` definitions and `roadrunner.hdmap.StencilMarking` instances. Used for road surface stencils (speed numbers, arrows, text). Same type+instance pattern with bounding box placement.

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique stencil type ID |
| `.assetPath` | string | Yes | Relative path to stencil image asset |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique stencil instance ID |
| `.markingTypeID` | string | Yes | Reference to a StencilMarkingType ID |
| `.center` | [x y z] | Yes | Position in ENU meters |
| `.dimension` | [halfL halfW halfH] | Yes | Half-extents in meters |
| `.geoOrientation` | [roll pitch heading] | No | Radians (default [0 0 0]) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.StencilMarkingType`
- `instanceArray` — column vector of `roadrunner.hdmap.StencilMarking`

## Example
```matlab
ts.id = "SpeedStencil30"; ts.assetPath = "Assets/Markings/Stencils/Speed30.png";
is.id = "Stencil_1"; is.markingTypeID = "SpeedStencil30";
is.center = [50 -1.75 0]; is.dimension = [1.5 0.75 0.001];
[stTypes, stInstances] = rrhd_authoring.build.stencilMarkings(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
