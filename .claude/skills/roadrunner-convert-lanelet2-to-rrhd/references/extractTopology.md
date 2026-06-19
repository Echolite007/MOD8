# Extracting Topology

Determines predecessor/successor relationships between lanelets using boundary endpoint node matching.

## Primary Method: Boundary Endpoint Node Matching

Two lanelets are sequential if their boundary ways share endpoint nodes. This captures ~96% of lane connectivity including intersection connections that proximity methods miss.

**Critical: Account for opposing boundary directions.** Left and right boundaries of a lanelet may run in opposite directions (common at intersections). The "last node" of a reversed boundary is at the lane START, not end.

### Detecting Opposing Boundaries

```matlab
leftGeom = geom(leftWayID);
rightGeom = geom(rightWayID);
leftDir = leftGeom(end,:) - leftGeom(1,:);
rightDir = rightGeom(end,:) - rightGeom(1,:);
isRightReversed = dot(leftDir, rightDir) < 0;
```

### Computing Effective Start/End Nodes

Use left boundary as canonical direction reference:

```matlab
% Left boundary: always canonical
effectiveStartLeft = wayFirstNode(leftWayID);
effectiveEndLeft = wayLastNode(leftWayID);

% Right boundary: flip if opposing
if isRightReversed
    effectiveStartRight = wayLastNode(rightWayID);   % last = lane start
    effectiveEndRight = wayFirstNode(rightWayID);    % first = lane end
else
    effectiveStartRight = wayFirstNode(rightWayID);
    effectiveEndRight = wayLastNode(rightWayID);
end
```

### Connection Logic

```matlab
% A → B if A's effective end matches B's effective start (either side)
if strcmp(effectiveEndLeft_A, effectiveStartLeft_B) || ...
   strcmp(effectiveEndRight_A, effectiveStartRight_B)
    topo(A).successors(end+1) = lanelets(B).id;
    topo(B).predecessors(end+1) = lanelets(A).id;
end
```

### Why Not Simple Node Matching?

Simple `wayLastNode == wayFirstNode` without flip detection creates false connections for opposing-boundary lanes:
- Lane_124's right boundary ends at node X (which is at lane START due to reversal)
- Lane_56's right boundary starts at node X (which is at lane START)
- Simple matching says "Lane_124 → Lane_56" but actually both STARTs are at node X
- Results in 71m+ gaps between "connected" lanes

With flip detection, effective end/start are correct and all gaps are either ~0m (direct) or ~3m (intersection crossings).

## Fallback: Center Line Proximity

For unmatched pairs after node matching, use geometry proximity:

```matlab
THRESH = 1.0; % meters
d = norm(endPts(i,:) - startPts(j,:));
if d < THRESH
    topo(i).successors(end+1) = lanelets(j).id;
    topo(j).predecessors(end+1) = lanelets(i).id;
end
```

## Endpoint Gaps After Topology

Connected lanes will have two types of gaps:
- **~0m**: Directly adjacent lanes sharing a boundary
- **~2-4m**: Intersection crossings (lane center to next lane center across junction)

Do NOT snap intersection-crossing gaps. Only snap gaps < 1.5m. The ~3m gaps are real physical distances — RoadRunner uses topology references for routing, not geometric coincidence.

## Performance Note

The O(n²) comparison is acceptable for maps with < 1000 lanelets. For larger maps, build a node-to-lanelet index for O(n) lookup.

----

Copyright 2026 The MathWorks, Inc.
