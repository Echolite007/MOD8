# Skill: assembleMap

**Package:** `rrhd_authoring.build`
**Function:** `rrMap = rrhd_authoring.build.assembleMap(parts, Name=Value)`
**Source:** `+rrhd_authoring/+build/assembleMap.m`

## Description
Assembles all RRHD entity arrays into a single `roadrunnerHDMap` object. Auto-computes geographic boundary from geometry. Optionally writes `.rrhd` file and shows preview plot.

## Inputs

### parts — struct with optional fields
| Field | Type | Description |
|-------|------|-------------|
| `.lanes` | Lane[] | Lane objects |
| `.laneBoundaries` | LaneBoundary[] | Lane boundary objects |
| `.laneGroups` | LaneGroup[] | Lane group objects |
| `.laneMarkings` | LaneMarking[] | Lane marking definitions |
| `.speedLimits` | SpeedLimit[] | Speed limit definitions |
| `.junctions` | Junction[] | Junction objects |
| `.signTypes` | SignType[] | Sign type definitions |
| `.signs` | Sign[] | Sign instances |
| `.signalTypes` | SignalType[] | Signal type definitions |
| `.signals` | Signal[] | Signal instances |
| `.staticObjectTypes` | StaticObjectType[] | Object type definitions |
| `.staticObjects` | StaticObject[] | Object instances |
| `.barrierTypes` | BarrierType[] | Barrier type definitions |
| `.barriers` | Barrier[] | Barrier instances |
| `.stencilMarkingTypes` | StencilMarkingType[] | Stencil type definitions |
| `.stencilMarkings` | StencilMarking[] | Stencil instances |
| `.curveMarkingTypes` | CurveMarkingType[] | Curve marking type definitions |
| `.curveMarkings` | CurveMarking[] | Curve marking instances |
| `.parkingEdges` | ParkingEdge[] | Parking edges |
| `.parkingSpaces` | ParkingSpace[] | Parking spaces |
| `.crgDefinitions` | CrgDefinition[] | CRG surface definitions |

### Name-Value Options
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Author` | string | `"RRHD Skills"` | Map author |
| `GeoReference` | [lat lon] | [0 0] | Geographic origin |
| `GeographicBoundary` | 2x3 double | auto-computed | [min; max] bounds |
| `OutputFile` | string | `""` | If set, writes `.rrhd` file |
| `Preview` | logical | false | If true, calls `plot()` |

## Output
`rrMap` — a `roadrunnerHDMap` object ready for use or export.

## Implementation Detail
> **Writing:** Use `write(rrMap, "output.rrhd")` — the `write` method is on the object.
>
> **Reading back:** Use `rrMap = roadrunnerHDMap; read(rrMap, "file.rrhd")` — do NOT pass
> the file to the constructor. The constructor takes no arguments.
>
> **GeographicBoundary:** Must be 2x3 double `[minX minY minZ; maxX maxY maxZ]`.
> Compute from all boundary and lane geometry.

## Example
```matlab
parts.lanes = myLanes;
parts.laneBoundaries = myBoundaries;
parts.laneMarkings = myMarkings;
rrMap = rrhd_authoring.build.assembleMap(parts, ...
    Author="MyConverter", ...
    GeoReference=[42.3 -71.35], ...
    OutputFile="output.rrhd", ...
    Preview=true);
```

----

Copyright 2026 The MathWorks, Inc.
