# Lane Marking Asset Mapping

Maps marking type + color combinations to RoadRunner `.rrlms` asset paths.

## Unified Marking Table

| Type | Color | Asset Path | Source Formats |
|---|---|---|---|
| `solid` | white | `Markings/SolidSingleWhite.rrlms` | All |
| `solid` | yellow | `Markings/SolidSingleYellow.rrlms` | All |
| `dashed` / `broken` | white | `Markings/DashedSingleWhite.rrlms` | All |
| `dashed` / `broken` | yellow | `Markings/DashedSingleYellow.rrlms` | All |
| `solid_solid` / `SOLID SOLID` | white | `Markings/SolidDoubleWhite.rrlms` | OpenDRIVE, HERE |
| `solid_solid` / `SOLID SOLID` | yellow | `Markings/SolidDoubleYellow.rrlms` | All |
| `dashed_dashed` / `DASHED DASHED` | white | `Markings/DashedDoubleWhite.rrlms` | HERE |
| `dashed_dashed` / `DASHED DASHED` | yellow | `Markings/DashedDoubleYellow.rrlms` | HERE |
| `dashed_solid` / `DASHED SOLID` | white | `Markings/DashedSolidWhite.rrlms` | HERE |
| `dashed_solid` / `DASHED SOLID` | yellow | `Markings/DashedSolidYellow.rrlms` | All |
| `solid_dashed` / `SOLID DASHED` | white | `Markings/DashedSolidWhite.rrlms` (Reverse=true) | HERE |
| `solid_dashed` / `SOLID DASHED` | yellow | `Markings/DashedSolidYellow.rrlms` (Reverse=true) | HERE |
| `solidBroken` | white | `Markings/DashedShortSingleWhite.rrlms` | Apollo |
| `solidBroken` | yellow | `Markings/DashedShortSingleYellow.rrlms` | Apollo |
| `brokenSolid` | white | `Markings/DashedShortSingleWhite.rrlms` | Apollo |
| `brokenSolid` | yellow | `Markings/DashedShortSingleYellow.rrlms` | Apollo |
| `brokenBroken` | white | `Markings/DashedSingleWhite.rrlms` | Apollo |
| `brokenBroken` | yellow | `Markings/DashedSingleWhite.rrlms` | Apollo |
| `SHORT_DASHED_LINE` | white | `Markings/DashedShortSingleWhite.rrlms` | TomTom |
| `SHORT_DASHED_LINE` | yellow | `Markings/DashedShortSingleYellow.rrlms` | TomTom |
| `LONG_DASHED_LINE` | white | `Markings/DashedSingleWhite.rrlms` | TomTom |
| `LONG_DASHED_LINE` | yellow | `Markings/DashedSingleYellow.rrlms` | TomTom |
| `SINGLE_SOLID_LINE` | white | `Markings/SolidSingleWhite.rrlms` | TomTom |
| `SINGLE_SOLID_LINE` | yellow | `Markings/SolidSingleYellow.rrlms` | TomTom |
| `ALTERNATE_DASHED` | white | `Markings/DashedShortSingleWhite.rrlms` | HERE |
| `ALTERNATE_DASHED` | yellow | `Markings/DashedShortSingleYellow.rrlms` | HERE |

## Lanelet2 Boundary Subtype Mapping

| Lanelet2 `subtype` | Default Color | Asset Path |
|---|---|---|
| `solid` | white | `Markings/SolidSingleWhite.rrlms` |
| `dashed` | white | `Markings/DashedSingleWhite.rrlms` |
| `solid_solid` | yellow | `Markings/SolidDoubleYellow.rrlms` |
| `dashed_solid` | yellow | `Markings/DashedSolidYellow.rrlms` |
| `solid_dashed` | yellow | `Markings/SolidDashedYellow.rrlms` |

## Non-Marking Boundary Types (Barriers)

These boundary types map to extrusions, not lane markings:

| Source Type | Asset Path |
|---|---|
| `guardrail` / `GUARDRAIL` | `Extrusions/GuardRail.rrext` |
| `barrier` / `BARRIER_JERSEY` | `Extrusions/JerseyBarrier.rrext` |
| `FENCE` | `Extrusions/Fence.rrext` |

## MATLAB Construction Pattern

```matlab
lm = roadrunner.hdmap.LaneMarking;
lm.ID = "SolidSingleWhite";
rap = roadrunner.hdmap.RelativeAssetPath;
rap.AssetPath = "Assets/Markings/SolidSingleWhite.rrlms";
lm.AssetPath = rap;

% Assign to boundary via ParametricAttribution
pa = roadrunner.hdmap.ParametricAttribution;
pa.Span = [0 1];
ref = roadrunner.hdmap.Reference;
ref.ID = "SolidSingleWhite";
mr = roadrunner.hdmap.MarkingReference;
mr.MarkingID = ref;
mr.FlipLaterally = false;
pa.MarkingReference = mr;
boundary.ParametricAttributes = pa;
```

----

Copyright 2026 The MathWorks, Inc.
