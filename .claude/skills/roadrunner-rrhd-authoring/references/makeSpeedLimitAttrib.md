# Skill: makeSpeedLimitAttrib

**Package:** `rrhd_authoring.utils`
**Function:** `pa = rrhd_authoring.utils.makeSpeedLimitAttrib(speedLimitID, span)`
**Source:** `+rrhd_authoring/+utils/makeSpeedLimitAttrib.m`

## Description
Creates a `ParametricAttribution` with a `SpeedLimitReference` for attaching speed limits to lanes over a parametric span.

## Inputs
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `speedLimitID` | string | (required) | ID of the SpeedLimit to reference |
| `span` | [1x2] double | `[0 1]` | Parametric span [start end] in [0,1] |

## Output
`pa` — `roadrunner.hdmap.ParametricAttribution` with `.SpeedLimitReference` and `.Span`.

## Implementation
> **Gotcha:** `SpeedLimitReference.SpeedLimitID` expects a `roadrunner.hdmap.Reference` object,
> not a string. All `roadrunner.hdmap` objects require create-then-assign, not constructor args.

```matlab
ref = roadrunner.hdmap.Reference;
ref.ID = speedLimitID;

slRef = roadrunner.hdmap.SpeedLimitReference;
slRef.SpeedLimitID = ref;

pa = roadrunner.hdmap.ParametricAttribution;
pa.Span = span;
pa.SpeedLimitReference = slRef;
```

## Reading back (property access path)
```matlab
pa.SpeedLimitReference.SpeedLimitID.ID  % returns the speed limit ID string
```

## Example
```matlab
pa = rrhd_authoring.utils.makeSpeedLimitAttrib("SL_50kph", [0 1]);
```

----

Copyright 2026 The MathWorks, Inc.
