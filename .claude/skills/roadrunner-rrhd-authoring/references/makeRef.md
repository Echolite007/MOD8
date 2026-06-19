# Skill: makeRef

**Package:** `rrhd_authoring.utils`
**Function:** `ref = rrhd_authoring.utils.makeRef(id)`
**Source:** `+rrhd_authoring/+utils/makeRef.m`

## Description
Creates a `roadrunner.hdmap.Reference` object for cross-linking RRHD entities. Used throughout all build functions to create ID references.

## Inputs
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | ID of the referenced entity |

## Output
`ref` — `roadrunner.hdmap.Reference` object with `ID` set to the given string.

## Implementation
> **Gotcha:** `roadrunner.hdmap.Reference` does NOT support constructor name-value args.
> You must create, then assign `.ID` as a separate step.

```matlab
ref = roadrunner.hdmap.Reference;
ref.ID = id;
```

## Example
```matlab
ref = rrhd_authoring.utils.makeRef("SignType_Stop");
```

----

Copyright 2026 The MathWorks, Inc.
