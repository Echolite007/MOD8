# Sign Code Mapping (Lanelet2 → RoadRunner)

Maps standard Lanelet2 `sign_type` codes to RoadRunner asset paths.

## Function Pattern

```matlab
function [assetPath, defaultDim, objectType] = mapSignCode(signCode)
% Returns empty assetPath if unmapped (caller should skip)
```

## Lookup Table

### Traffic Lights / Signals
| Code pattern | Asset Path | Dimensions | Type |
|---|---|---|---|
| Contains `traffic_light` or `signal` | `Assets/Props/Signals/Signal_3Light_Post01.fbx` | [0.26 0.32 0.58] | `signal` |

### US MUTCD Signs
| Code(s) | Asset Path | Type |
|---|---|---|
| `us_r1_1`, `stop`, `us_stop` | `Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg` | `sign` |
| `us_r1_2`, `yield`, `us_yield` | `Assets/Signs/US/Regulatory Signs/Sign_R1-2.svg` | `sign` |
| `us_r2_1`, or `us_` + contains `speed` | `Assets/Signs/US/Regulatory Signs/Sign_R2-1.svg` | `sign` |
| `us_r3_1`, `us_no_right_turn` | `Assets/Signs/US/Regulatory Signs/Sign_R3-1.svg` | `sign` |
| `us_r3_2`, `us_no_left_turn` | `Assets/Signs/US/Regulatory Signs/Sign_R3-2.svg` | `sign` |
| `us_r3_4`, `us_no_u_turn` | `Assets/Signs/US/Regulatory Signs/Sign_R3-4.svg` | `sign` |
| `us_r6_1`, `us_one_way` | `Assets/Signs/US/Regulatory Signs/Sign_R6-1.svg` | `sign` |
| `us_r5_1`, `us_do_not_enter` | `Assets/Signs/US/Regulatory Signs/Sign_R5-1.svg` | `sign` |

### German StVO Signs
| Code pattern | Asset Path (fallback) | Type |
|---|---|---|
| `de206` or `de_stop` | `Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg` | `sign` |
| `de205` or `de_yield` | `Assets/Signs/US/Regulatory Signs/Sign_R1-2.svg` | `sign` |
| starts with `de274` | `Assets/Signs/US/Regulatory Signs/Sign_R2-1.svg` | `sign` |
| starts with `de267` | `Assets/Signs/US/Regulatory Signs/Sign_R5-1.svg` | `sign` |

### Generic / Autoware Conventions (fallback)
| Code contains | Asset Path | Type |
|---|---|---|
| `stop` or `stop_sign` | `Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg` | `sign` |
| `yield` or `give_way` | `Assets/Signs/US/Regulatory Signs/Sign_R1-2.svg` | `sign` |
| `speed` | `Assets/Signs/US/Regulatory Signs/Sign_R2-1.svg` | `sign` |

### Defaults
- Default sign dimensions: `[0 0.50 0.50]` (flat, 0.5m × 0.5m)
- Match order: traffic lights → US MUTCD → German StVO → generic keywords
- If no match: return empty `assetPath` (caller skips this sign)

## Orientation Estimation

Signs/signals face approaching traffic. Estimate orientation by finding the nearest lanelet center line segment and rotating 180°:

```matlab
% For each lanelet center geometry, find closest segment to sign position
% Project sign pos onto segment, get segment direction
% Sign faces opposite: yawRad = atan2(-segDir(2), -segDir(1))
% orientation = [0, 0, rad2deg(yawRad)]
```

## Standard Regulatory Element Processing

### `subtype=traffic_sign`
1. Get `sign_type` tag from the relation → look up asset via table above
2. **Fallback:** If `sign_type` is empty, get `subtype` tag from the referred way (e.g., `stop_sign`, `yield_sign`)
3. Skip if code is empty or `"unknown"`
4. Find physical location from `refers` member (way centroid or node coords)
5. Estimate orientation from nearest lanelet
6. Create SignType + Sign instance (use `GeoOrientedBoundingBox` for Geometry)

### `subtype=traffic_light`
1. Use `traffic_light` asset path from table
2. Find location from `refers` member
3. Estimate orientation from nearest lanelet
4. Create SignalType + Signal instance

### `subtype=speed_limit`
1. Extract speed value from `sign_type` (regex `(\d+)$`) or `speed_limit` tag
2. Apply to all `refers` relation members (lanelet speed_limit field)
3. Optionally create a speed limit sign (if `sign_type` is present)

## Speed Value Extraction

```matlab
% From sign_type tag like "de274-30" → extract trailing digits
tokens = regexp(signType, '(\d+)$', 'tokens');
if ~isempty(tokens), speedVal = str2double(tokens{1}{1}); end
% Also check explicit 'speed_limit' tag on the relation
```

----

Copyright 2026 The MathWorks, Inc.
