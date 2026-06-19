# Skill: speedLimits

**Package:** `rrhd_authoring.build`
**Function:** `slArray = rrhd_authoring.build.speedLimits(specs)`
**Source:** `+rrhd_authoring/+build/speedLimits.m`

## Description
Creates `roadrunner.hdmap.SpeedLimit` definition objects. Referenced by lanes via parametric attributions.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique speed limit ID (referenced by lanes) |
| `.value` | int32 | Yes | Speed value |
| `.unit` | string | Yes | `"MPH"` / `"KPH"` / `"MPS"` |

## Output
`slArray` — column vector of `roadrunner.hdmap.SpeedLimit` objects.

## Example
```matlab
specs(1) = struct('id',"SL_50kph", 'value',int32(50), 'unit',"KPH");
sls = rrhd_authoring.build.speedLimits(specs);
```

----

Copyright 2026 The MathWorks, Inc.
