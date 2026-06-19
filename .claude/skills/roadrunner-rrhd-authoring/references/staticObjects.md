# Skill: staticObjects

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.staticObjects(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/staticObjects.m`

## Description
Creates `roadrunner.hdmap.StaticObjectType` definitions and `roadrunner.hdmap.StaticObject` instances. Same type+instance pattern as signs/signals.

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique object type ID |
| `.assetPath` | string | Yes | Relative path to 3D mesh asset (`.fbx`, etc.) |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique object instance ID |
| `.objectTypeID` | string | Yes | Reference to a StaticObjectType ID |
| `.center` | [x y z] | Yes | Position in ENU meters |
| `.dimension` | [halfL halfW halfH] | Yes | Half-extents in meters |
| `.geoOrientation` | [roll pitch heading] | No | Radians (default [0 0 0]) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.StaticObjectType`
- `instanceArray` — column vector of `roadrunner.hdmap.StaticObject`

## Example
```matlab
ts.id = "TreeType"; ts.assetPath = "Assets/Props/Trees/Eucalyptus_Sm01.fbx";
is(1).id = "Tree1"; is(1).objectTypeID = "TreeType";
is(1).center = [20 15 0]; is(1).dimension = [2 2 4.5];
[objTypes, objInstances] = rrhd_authoring.build.staticObjects(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
