# rrhd_mapLanelet2SignCode

Maps Lanelet2 sign/signal type codes to RoadRunner asset paths, default bounding box dimensions, and object type classification.

## Signature

```matlab
[assetPath, defaultDim, objectType] = rrhd_mapLanelet2SignCode(signCode)
```

## Inputs

| Parameter | Type | Description |
|-----------|------|-------------|
| `signCode` | `string` | Lanelet2 `sign_type` value (e.g. `"us_r1_1"`, `"de274-30"`, `"traffic_light"`) |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `assetPath` | `string` | RoadRunner relative asset path (e.g. `"Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg"`) |
| `defaultDim` | `1x3 double` | Default bounding box `[width, depth, height]` in meters |
| `objectType` | `string` | `"sign"` or `"signal"` — determines which RRHD object type to create |

## Supported Sign Code Families

### US MUTCD (Federal Highway Administration)
| Code | Meaning | Asset |
|------|---------|-------|
| `us_r1_1` | Stop | `Sign_R1-1.svg` |
| `us_r1_2` | Yield | `Sign_R1-2.svg` |
| `us_r2_1` | Speed Limit | `Sign_R2-1.svg` |
| `us_r3_1` | No Right Turn | `Sign_R3-1.svg` |
| `us_r3_2` | No Left Turn | `Sign_R3-2.svg` |
| `us_r3_3` | No U-Turn | `Sign_R3-3.svg` |
| `us_r3_4` | No Turns | `Sign_R3-4.svg` |

### German StVO
| Code | Meaning | Asset (US fallback) |
|------|---------|---------------------|
| `de206` | Stop | `Sign_R1-1.svg` |
| `de205` | Yield | `Sign_R1-2.svg` |
| `de274-*` | Speed Limit | `Sign_R2-1.svg` |

### Generic Keywords
| Pattern | Mapping |
|---------|---------|
| Contains `stop` | Stop sign |
| Contains `yield` | Yield sign |
| Contains `speed` | Speed limit sign |
| Contains `traffic_light` or `signal` | Traffic signal (`objectType = "signal"`) |

### Default Dimensions
| Object Type | Width | Depth | Height |
|-------------|-------|-------|--------|
| Sign | 0.00 | 0.50 | 0.50 |
| Signal | 0.26 | 0.32 | 0.58 |

## Unmapped Codes

If a sign code doesn't match any known pattern, returns `assetPath = ""` (empty). The caller should skip unmapped codes.

## Example

```matlab
[path, dim, type] = rrhd_mapLanelet2SignCode("us_r1_1");
% path = "Assets/Signs/US/Regulatory Signs/Sign_R1-1.svg"
% dim  = [0.00, 0.50, 0.50]
% type = "sign"

[path, dim, type] = rrhd_mapLanelet2SignCode("traffic_light");
% path = "Assets/Props/Signals/Signal_3Light_Post01.fbx"
% dim  = [0.26, 0.32, 0.58]
% type = "signal"
```

----

Copyright 2026 The MathWorks, Inc.
