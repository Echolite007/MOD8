# Extracting Junctions

Infers RRHD Junction objects from Lanelet2 data. Handles both explicit junction multipolygons and implicit inference from `turn_direction` tags.

## Two Methods (try explicit first, fall back to inference)

### Method 1: Explicit Junction Multipolygons

If the OSM data contains `type=multipolygon`, `subtype=junction` relations, use their polygon geometry and lane references directly.

### Method 2: Infer from turn_direction Tags (Primary for most maps)

Most Lanelet2 maps define junctions implicitly via lanelets with `turn_direction` tags (`left`, `right`, `straight`). These are the intersection interior lanes.

#### Step 1: Identify Junction Lanelets

```matlab
juncLaneIdx = [];
for i = 1:numel(lanelets)
    if lanelets(i).tags.isKey('turn_direction')
        juncLaneIdx(end+1) = i;
    end
end
```

#### Step 2: Compute Centroids

```matlab
juncCentroids = zeros(numel(juncLaneIdx), 3);
for k = 1:numel(juncLaneIdx)
    juncCentroids(k,:) = mean(centerGeoms(char(lanelets(juncLaneIdx(k)).id)), 1);
end
```

#### Step 3: BFS Cluster by Centroid Proximity

```matlab
CLUSTER_THRESH = 10;       % meters
MIN_JUNCTION_LANES = 3;    % discard fragments
visited = false(1, numel(juncLaneIdx));
juncClusters = {};
for k = 1:numel(juncLaneIdx)
    if visited(k), continue; end
    queue = k; cluster = [];
    while ~isempty(queue)
        curr = queue(1); queue(1) = [];
        if visited(curr), continue; end
        visited(curr) = true;
        cluster(end+1) = curr;
        dists = vecnorm(juncCentroids - juncCentroids(curr,:), 2, 2);
        neighbors = find(dists < CLUSTER_THRESH & ~visited');
        queue = [queue, neighbors'];
    end
    if numel(cluster) >= MIN_JUNCTION_LANES
        juncClusters{end+1} = cluster;
    end
end
```

#### Step 4: Build Junction Polygon

For polygon shape construction (outer boundary tracing + endpoint chaining), see `roadrunner-rrhd-authoring` skill's [references/junctionPolygon.md](../roadrunner-rrhd-authoring/references/junctionPolygon.md).

**Lanelet2-specific outer boundary identification:**

```matlab
% Count boundary references within this cluster
bndWayCount = containers.Map('KeyType','char','ValueType','double');
for j = 1:numel(cluster)
    li = regularLaneIdx(juncLaneIdx(cluster(j)));
    leftWID = char(lanelets(li).leftWayID);
    rightWID = char(lanelets(li).rightWayID);
    if bndWayCount.isKey(leftWID), bndWayCount(leftWID) = bndWayCount(leftWID)+1;
    else, bndWayCount(leftWID) = 1; end
    if bndWayCount.isKey(rightWID), bndWayCount(rightWID) = bndWayCount(rightWID)+1;
    else, bndWayCount(rightWID) = 1; end
end

% Outer boundaries = referenced exactly once within the cluster
outerSegs = {};
bndKeys = bndWayCount.keys;
for b = 1:numel(bndKeys)
    wID = bndKeys{b};
    if bndWayCount(wID) == 1 && geomMap.isKey(wID)
        outerSegs{end+1} = geomMap(wID);  % Nx3 polyline
    end
end
```

Then apply the **endpoint chaining algorithm** from `junctionPolygon.md` to order `outerSegs` into a closed polygon perimeter.

#### Critical Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `CLUSTER_THRESH` | 10m | Separates distinct intersections. 30m merges adjacent. 15m still chains through intermediate lanes. |
| `MIN_JUNCTION_LANES` | 3 | Minimum lanes to form a junction. Single/pair fragments are discarded. |

#### WARNING: Do NOT use union-find for clustering

Union-find with shared-predecessor/successor criteria causes **transitive chaining** that merges distant intersections. Example: 80 lanes spanning 200m × 183m collapsed into one polygon. Always use spatial proximity BFS (10m).

#### Fallback Topology Method (if no turn_direction tags exist)

- Lane is junction if: (has predecessor with >1 successors) OR (has successor with >1 predecessors)

## Regulatory Elements

Traffic light regulatory elements (`type=regulatory_element`, `subtype=traffic_light`) can be linked to junctions by matching controlled lane IDs:

```matlab
for each regElement:
    for each junction:
        overlap = intersect(regElement.controlledLaneIDs, junction.laneIDs);
        if ~isempty(overlap)
            junction.configurations(end+1) = buildConfigFromRegElement(regElement);
        end
    end
end
```

Signal phase timing requires `custom:phase_*` tags (standard Lanelet2 has no signal phase encoding).

## Building RRHD Junction Objects

```matlab
jObj = roadrunner.hdmap.Junction;
jObj.ID = "Junction_1";

% Lane references
for k = 1:numel(laneIDs)
    ref = roadrunner.hdmap.Reference;
    ref.ID = laneIDs(k);
    jObj.Lanes(end+1) = ref;
end

% MultiPolygon geometry
mp = roadrunner.hdmap.MultiPolygon;
pg = roadrunner.hdmap.Polygon;
pg.ExteriorRing = polygonPts;  % Nx3 closed ring
mp.Polygons(end+1) = pg;
jObj.Geometry = mp;
```

----

Copyright 2026 The MathWorks, Inc.
