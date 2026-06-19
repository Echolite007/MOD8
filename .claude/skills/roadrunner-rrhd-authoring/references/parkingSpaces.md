# Skill: parkingSpaces

**Package:** `rrhd_authoring.build`
**Function:** `[edges, spaces] = rrhd_authoring.build.parkingSpaces(edgeSpecs, spaceSpecs)`
**Source:** `+rrhd_authoring/+build/parkingSpaces.m`

## Description
Creates `roadrunner.hdmap.ParkingEdge` and `roadrunner.hdmap.ParkingSpace` objects. Parking spaces are defined by a set of edges (some open for entry/exit).

## Inputs

### edgeSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique edge ID |
| `.geometry` | Nx2 or Nx3 double | Yes | Edge polyline in ENU meters |
| `.open` | logical | Yes | `true` = entry/exit edge |
| `.markingID` | string | No | Reference to a LaneMarking ID |
| `.flipMarkingLaterally` | logical | No | Flip marking (default false) |

### spaceSpecs — struct array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique parking space ID |
| `.edgeIDs` | string array | Yes | References to ParkingEdge IDs |
| `.metadata` | struct array | No | Each with `.name`, `.value` |

## Output
- `edges` — column vector of `roadrunner.hdmap.ParkingEdge`
- `spaces` — column vector of `roadrunner.hdmap.ParkingSpace`

## Example
```matlab
es(1).id = "PE_1"; es(1).geometry = [10 5 0; 12.5 5 0]; es(1).open = false;
es(2).id = "PE_2"; es(2).geometry = [12.5 5 0; 12.5 8 0]; es(2).open = true;
ss.id = "PS_1"; ss.edgeIDs = ["PE_1","PE_2"];
[pkEdges, pkSpaces] = rrhd_authoring.build.parkingSpaces(es, ss);
```

----

Copyright 2026 The MathWorks, Inc.
