# Sign Asset Mapping

Maps traffic sign types to RoadRunner asset paths across all source formats.

## US MUTCD Signs (North America)

Signs use MUTCD regulatory numbering: `Sign_R<section>-<number>.svg`

| Sign Type | MUTCD Code | Asset Path |
|---|---|---|
| STOP | R1-1 | `Signs/US/Regulatory Signs/Sign_R1-1.svg` |
| YIELD | R1-2 | `Signs/US/Regulatory Signs/Sign_R1-2.svg` |
| SPEED_LIMIT | R2-1(N) | `Signs/US/Regulatory Signs/Sign_R2-1(<N>).svg` |
| SPEED_LIMIT (blank) | R2-1(Blank) | `Signs/US/Regulatory Signs/Sign_R2-1(Blank).svg` |
| SPEED_LIMIT (template) | — | `Signs/US/Regulatory Signs/Sign_SpeedLimit.svg` |
| NO_STOPPING | — | `Signs/US/Regulatory Signs/Sign_NoStopping.svg` |
| Blank (white) | — | `Signs/US/Sign_BlankWhite.rrsign` |
| Blank (yellow panel) | — | `Signs/US/Sign_BlankYellowPanel.svg` |

**Speed limit values available:** 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80

**Pattern:** `Signs/US/Regulatory Signs/Sign_R2-1(<value>).svg`

## German StVO Signs (OpenDRIVE)

Signs use StVO numbering: `Sign_<code>.svg`

| StVO Code | Value | Asset Path |
|---|---|---|
| 206 (Stop) | — | `Signs/Germany/Regulatory Signs/Sign_206.svg` |
| 205 (Yield) | — | `Signs/Germany/Regulatory Signs/Sign_205.svg` |
| 274 (Speed) | 10 | `Signs/Germany/Regulatory Signs/Sign_274(10).svg` |
| 274 (Speed) | 20 | `Signs/Germany/Regulatory Signs/Sign_274(20).svg` |
| 274 (Speed) | 30 | `Signs/Germany/Regulatory Signs/Sign_274(30).svg` |
| 274 (Speed) | 40 | `Signs/Germany/Regulatory Signs/Sign_274(40).svg` |
| 274 (Speed) | 50 | `Signs/Germany/Regulatory Signs/Sign_274(50).svg` |
| 274 (Speed) | 60 | `Signs/Germany/Regulatory Signs/Sign_274(60).svg` |
| 274 (Speed) | 70 | `Signs/Germany/Regulatory Signs/Sign_274(70).svg` |
| 274 (Speed) | 80 | `Signs/Germany/Regulatory Signs/Sign_274(80).svg` |
| 274 (Speed) | 100 | `Signs/Germany/Regulatory Signs/Sign_274(100).svg` |
| 274 (Speed) | 110 | `Signs/Germany/Regulatory Signs/Sign_274(110).svg` |
| 274 (Speed) | 120 | `Signs/Germany/Regulatory Signs/Sign_274(120).svg` |
| 274 (Speed) | 130 | `Signs/Germany/Regulatory Signs/Sign_274(130).svg` |
| Warning (fallback) | — | `Signs/Germany/Warning Signs/Sign_101.svg` |

**Pattern:** `Signs/Germany/Regulatory Signs/Sign_274(<value>).svg`

## Japanese Signs (Lanelet2 maps in Japan)

Signs use Japanese regulatory numbering: `Sign_<code>.svg`

| Sign Type | Code | Asset Path |
|---|---|---|
| STOP | 330-A | `Signs/Japan/Regulatory Signs/Sign_330-A.svg` |
| STOP (variant) | 330-B | `Signs/Japan/Regulatory Signs/Sign_330-B.svg` |
| SPEED_LIMIT | 323 (N) | `Signs/Japan/Regulatory Signs/Sign_323 (<N>).svg` |
| NO_ENTRY | 302 | `Signs/Japan/Regulatory Signs/Sign_302.svg` |
| NO_PARKING | 316 | `Signs/Japan/Regulatory Signs/Sign_316.svg` |
| NO_STOPPING | 318 | `Signs/Japan/Regulatory Signs/Sign_318.svg` |
| ONE_WAY | 325 | `Signs/Japan/Regulatory Signs/Sign_325.svg` |
| NO_OVERTAKING | 314 | `Signs/Japan/Regulatory Signs/Sign_314.svg` |
| NO_U_TURN | 312 | `Signs/Japan/Regulatory Signs/Sign_312.svg` |
| Warning (fallback) | 215 | `Signs/Japan/Warning Signs/Sign_215.svg` |

**Speed limit values available:** 10, 20, 30, 40, 50, 60, 70, 80, 90, 100

**Pattern:** `Signs/Japan/Regulatory Signs/Sign_323 (<value>).svg` (note: space before parenthesis)

## Region Detection from GeoReference

Determine sign region from the map's geoReference latitude/longitude:

| Latitude Range | Longitude Range | Region | Sign Prefix |
|---|---|---|---|
| 24–46 | 122–154 | Japan | `Signs/Japan/` |
| 35–72 | -10–25 | Germany/EU | `Signs/Germany/` |
| 24–50 | -130– -60 | US/NA | `Signs/US/` |
| 50–60 | -8–2 | UK | `Signs/UK/` |
| 18–54 | 73–135 | China | `Signs/China/` |
| (fallback) | — | US | `Signs/US/` |

**Implementation:**
```matlab
function region = detectSignRegion(geoRef)
    lat = geoRef(1); lon = geoRef(2);
    if lat >= 24 && lat <= 46 && lon >= 122 && lon <= 154
        region = "Japan";
    elseif lat >= 35 && lat <= 72 && lon >= -10 && lon <= 25
        region = "Germany";
    elseif lat >= 50 && lat <= 60 && lon >= -8 && lon <= 2
        region = "UK";
    elseif lat >= 18 && lat <= 54 && lon >= 73 && lon <= 135
        region = "China";
    else
        region = "US";  % default fallback
    end
end
```

## Blank/Fallback Signs

| Type | Asset Path |
|---|---|
| White blank (US) | `Signs/US/Sign_BlankWhite.rrsign` |
| Yellow panel (US) | `Signs/US/Sign_BlankYellowPanel.svg` |
| Speed blank (US) | `Signs/US/Regulatory Signs/Sign_R2-1(Blank).svg` |
| Warning (Germany) | `Signs/Germany/Warning Signs/Sign_101.svg` |
| Warning (Japan) | `Signs/Japan/Warning Signs/Sign_215.svg` |

## Lanelet2 Sign Code Mapping

| Lanelet2 `sign_type` / way `subtype` | Resolved Asset |
|---|---|
| `stop`, `stop_sign`, `us_stop`, `de206` | Stop sign (region-appropriate) |
| `yield`, `give_way`, `us_yield`, `de205` | Yield sign |
| `us_r1_1` | `Signs/US/Regulatory Signs/Sign_R1-1.svg` |
| `us_r1_2` | `Signs/US/Regulatory Signs/Sign_R1-2.svg` |
| `us_r2_1` or contains `speed` | `Signs/US/Regulatory Signs/Sign_R2-1.svg` |
| `de274` + value | German speed limit sign |
| `traffic_light` | → Signal (not sign) |

## OpenDRIVE Signal Resolution

OpenDRIVE uses `<signal type="274" country="DE" value="30"/>`:
1. Match by `Type` + `Country` + `Value` in the lookup table
2. If no match, fall back to country-appropriate blank sign
3. Variant field (0-3) all map to same asset

## Sign Geometry (RRHD)

```matlab
st = roadrunner.hdmap.SignType;
st.ID = "SpeedLimit_30";
rap = roadrunner.hdmap.RelativeAssetPath;
rap.AssetPath = "Assets/Signs/US/Regulatory Signs/Sign_R2-1(30).svg";
st.AssetPath = rap;

sg = roadrunner.hdmap.Sign;
sg.ID = "Sign_1";
gobb = roadrunner.hdmap.GeoOrientedBoundingBox;
gobb.Center = [x, y, z];
gobb.Dimension = [0, 0.6, 0.6];  % flat sign, width x height
gobb.GeoOrientation = [yawDeg, 0, 0];  % [heading, pitch, roll] in degrees
sg.Geometry = gobb;
typeRef = roadrunner.hdmap.Reference;
typeRef.ID = "SpeedLimit_30";
sg.SignTypeReference = typeRef;
```

----

Copyright 2026 The MathWorks, Inc.
