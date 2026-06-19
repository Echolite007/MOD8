# Skill: signals

**Package:** `rrhd_authoring.build`
**Function:** `[typeArray, instanceArray] = rrhd_authoring.build.signals(typeSpecs, instanceSpecs)`
**Source:** `+rrhd_authoring/+build/signals.m`

## Description
Creates `roadrunner.hdmap.SignalType` definitions and `roadrunner.hdmap.Signal` instances. Same type+instance pattern as signs.

## Inputs

### typeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique signal type ID |
| `.assetPath` | string | Yes | Relative path to signal asset |

### instanceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique signal instance ID |
| `.signalTypeID` | string | Yes | Reference to a SignalType ID |
| `.center` | [x y z] | Yes | Position in ENU meters |
| `.dimension` | [halfL halfW halfH] | Yes | Half-extents in meters |
| `.geoOrientation` | [roll pitch heading] | No | Radians (default [0 0 0]) |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `typeArray` — column vector of `roadrunner.hdmap.SignalType`
- `instanceArray` — column vector of `roadrunner.hdmap.Signal`

## Example
```matlab
ts.id = "TrafficLight3"; ts.assetPath = "Assets/Signals/TrafficLight3.fbx";
is.id = "TL_North"; is.signalTypeID = "TrafficLight3";
is.center = [0 10 5]; is.dimension = [0.15 0.3 0.45];
[sigTypes, sigInstances] = rrhd_authoring.build.signals(ts, is);
```

----

Copyright 2026 The MathWorks, Inc.
