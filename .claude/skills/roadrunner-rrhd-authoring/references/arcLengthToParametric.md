# Skill: arcLengthToParametric

**Package:** `rrhd_authoring.utils`
**Function:** `[paramStart, paramEnd] = rrhd_authoring.utils.arcLengthToParametric(geometry, meterStart, meterEnd)`
**Source:** `+rrhd_authoring/+utils/arcLengthToParametric.m`

## Description
Converts arc-length distance (meters) along a polyline to parametric [0,1] span. Needed because RRHD `ParametricAttribution` uses normalized spans, not meters.

## Inputs
| Parameter | Type | Description |
|-----------|------|-------------|
| `geometry` | Nx3 double | Polyline coordinates |
| `meterStart` | double | Start distance in meters (>= 0) |
| `meterEnd` | double | End distance in meters (>= 0) |

## Output
- `paramStart` — normalized start position in [0,1]
- `paramEnd` — normalized end position in [0,1]

## Algorithm
```matlab
diffs = diff(geometry);
segLengths = vecnorm(diffs, 2, 2);
totalLength = sum(segLengths);
paramStart = min(meterStart / totalLength, 1.0);
paramEnd = min(meterEnd / totalLength, 1.0);
```

## Example
```matlab
% Marking from meter 10 to meter 50 along a 100m boundary
[ps, pe] = rrhd_authoring.utils.arcLengthToParametric(boundaryGeom, 10, 50);
% ps = 0.1, pe = 0.5
```

----

Copyright 2026 The MathWorks, Inc.
