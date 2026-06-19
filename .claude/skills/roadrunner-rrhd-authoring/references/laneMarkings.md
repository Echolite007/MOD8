# Skill: laneMarkings

**Package:** `rrhd_authoring.build`
**Function:** `lmArray = rrhd_authoring.build.laneMarkings(specs)`
**Source:** `+rrhd_authoring/+build/laneMarkings.m`

## Description
Creates `roadrunner.hdmap.LaneMarking` definition objects. These are referenced by lane boundaries via parametric attributions.

## Inputs
`specs` — struct array, each element with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `.id` | string | Yes | Unique marking ID (referenced by boundaries) |
| `.assetPath` | string | Yes | Relative path to `.rrlms` asset |

### Common Asset Paths
- `"Assets/Markings/SolidSingleWhite.rrlms"`
- `"Assets/Markings/DashedSingleWhite.rrlms"`
- `"Assets/Markings/SolidSingleYellow.rrlms"`
- `"Assets/Markings/DashedSingleYellow.rrlms"`
- `"Assets/Markings/SolidDoubleYellow.rrlms"`

## Output
`lmArray` — column vector of `roadrunner.hdmap.LaneMarking` objects.

## Implementation Detail
> **Gotcha:** `LaneMarking.AssetPath` expects a `roadrunner.hdmap.RelativeAssetPath` object,
> not a plain string. Assigning a string directly will error.

```matlab
% Correct pattern for each marking:
lm = roadrunner.hdmap.LaneMarking;
lm.ID = "SolidWhite";
rap = roadrunner.hdmap.RelativeAssetPath;
rap.AssetPath = "Assets/Markings/SolidSingleWhite.rrlms";
lm.AssetPath = rap;
```

## Example
```matlab
specs(1) = struct('id',"SolidWhite", 'assetPath',"Assets/Markings/SolidSingleWhite.rrlms");
specs(2) = struct('id',"DblYellow",  'assetPath',"Assets/Markings/SolidDoubleYellow.rrlms");
lms = rrhd_authoring.build.laneMarkings(specs);
```

----

Copyright 2026 The MathWorks, Inc.
