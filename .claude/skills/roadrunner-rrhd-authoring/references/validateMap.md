# Skill: validateMap

**Package:** `rrhd_authoring.validate`
**Function:** `report = rrhd_authoring.validate.validateMap(rrMap)`
**Source:** `+rrhd_authoring/+validate/validateMap.m`

## Description
Validates a `roadrunnerHDMap` for structural correctness. Checks:
- Duplicate IDs across all entity types
- Dangling references (lane→boundary, lane→predecessor/successor, boundary→marking, instance→type)
- Geometry has >= 2 points
- Parametric spans within [0,1]
- GeoReference within valid lat/lon bounds
- Type-instance reference integrity (signs, signals, objects, barriers, stencils)

## Inputs
| Parameter | Type | Description |
|-----------|------|-------------|
| `rrMap` | roadrunnerHDMap | The map to validate |

## Output
`report` — struct with:
| Field | Type | Description |
|-------|------|-------------|
| `.errors` | string array | Blocking issues |
| `.warnings` | string array | Non-blocking issues |
| `.isValid` | logical | `true` if no errors |

## Example
```matlab
report = rrhd_authoring.validate.validateMap(rrMap);
if ~report.isValid
    disp(report.errors);
end
assert(report.isValid, "Validation failed: " + strjoin(report.errors, "; "));
```

----

Copyright 2026 The MathWorks, Inc.
