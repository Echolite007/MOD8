# Skill: makeMarkingAttrib

**Package:** `rrhd_authoring.utils`
**Function:** `pa = rrhd_authoring.utils.makeMarkingAttrib(markingID, span, flipLaterally)`
**Source:** `+rrhd_authoring/+utils/makeMarkingAttrib.m`

## Description
Creates a `ParametricAttribution` with a `MarkingReference` for attaching lane markings to boundaries over a parametric span.

## Inputs
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `markingID` | string | (required) | ID of the LaneMarking to reference |
| `span` | [1x2] double | `[0 1]` | Parametric span [start end] in [0,1] |
| `flipLaterally` | logical | `false` | Flip marking orientation laterally |

## Output
`pa` — `roadrunner.hdmap.ParametricAttribution` with `.MarkingReference` and `.Span`.

## Implementation
> **Gotcha:** `MarkingReference.MarkingID` expects a `roadrunner.hdmap.Reference` object,
> not a string. All `roadrunner.hdmap` objects require create-then-assign, not constructor args.

```matlab
ref = roadrunner.hdmap.Reference;
ref.ID = markingID;

mr = roadrunner.hdmap.MarkingReference;
mr.MarkingID = ref;
mr.FlipLaterally = flipLaterally;

pa = roadrunner.hdmap.ParametricAttribution;
pa.Span = span;
pa.MarkingReference = mr;
```

## Example
```matlab
pa = rrhd_authoring.utils.makeMarkingAttrib("SolidWhite", [0 1]);
pa = rrhd_authoring.utils.makeMarkingAttrib("SolidWhite", [0.2 0.8], true);
```

----

Copyright 2026 The MathWorks, Inc.
