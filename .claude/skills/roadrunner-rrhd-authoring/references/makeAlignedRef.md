# Skill: makeAlignedRef

**Package:** `rrhd_authoring.utils`
**Function:** `aRef = rrhd_authoring.utils.makeAlignedRef(id, alignment)`
**Source:** `+rrhd_authoring/+utils/makeAlignedRef.m`

## Description
Creates an `AlignedReference` for lane/boundary linking. Wraps a `Reference` with a direction alignment.

## Inputs
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | (required) | ID of the referenced entity |
| `alignment` | string | `"Forward"` | `"Forward"`, `"Backward"`, or `"Unspecified"` |

## Output
`aRef` — `roadrunner.hdmap.AlignedReference` with `.Reference.ID` and `.Alignment`.

## Implementation
> **Gotcha:** `roadrunner.hdmap` objects do NOT support constructor name-value args.
> Create each object, then assign properties. Also, `AlignedReference.Reference`
> requires a `roadrunner.hdmap.Reference` object — passing a string errors.

```matlab
ref = roadrunner.hdmap.Reference;
ref.ID = id;
aRef = roadrunner.hdmap.AlignedReference;
aRef.Reference = ref;
aRef.Alignment = alignment;
```

> **Empty-object trap:** You cannot dot-assign into an empty AlignedReference:
> `ln.LeftLaneBoundary.Reference = ref;` errors with "not allowed when object is empty".
> Always create a full AlignedReference object then assign it to the lane property.

## Example
```matlab
ref = rrhd_authoring.utils.makeAlignedRef("Lane1", "Forward");
```

----

Copyright 2026 The MathWorks, Inc.
