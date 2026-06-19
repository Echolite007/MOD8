# Reflector Calculator (Gaussian-Beam Analysis)

`reflectorCalculator` (R2026a) provides fast analytical design using Gaussian-beam methods -- no full-wave solve required. Computes efficiency, gain, beamwidth, and sidelobe level instantly. Bridges to `customDualReflectors` via `createAntenna` for full-wave verification.

## Feed Types

| FeedType | Description | Key Properties |
|----------|-------------|----------------|
| `"singlefed"` | Single horn feed | `RadiatingElement`, `RadiatorAperture` |
| `"arrayfed"` | Array of horns | `NumRadiators`, `Spacing` |
| `"patternfed"` | External pattern file | `FileName` (`.txt` or `.csv` only) |

## Radiating Element Options

`"horn"` (default), `"conicalhorn"`, `"corrugatedhorn"`, `"potterhorn"`

## Additional Properties

| Property | Default | Description |
|----------|---------|-------------|
| `RadiatorAperture` | 0.068 | Aperture of radiating element (m) |
| `FeedLoss` | 0 | Loss associated with radiating element (dB) |

## Single-Fed Analysis

```matlab
freq = 12e9;

rc = reflectorCalculator;
rc.Diameter = 1;           % meters
rc.FocalLength = 0.9;
rc.ClearanceHeight = 0.1;  % offset height
rc.FeedType = "singlefed";
rc.RadiatingElement = "horn";
rc.ScanAngle = 1;          % degrees off-boresight
rc.SurfaceError = 0;       % RMS surface error (m)

% Solve -- returns 18-metric table instantly
s = solve(rc, freq);
disp(s);

% Visualize
figure; plot(rc, Frequency=freq, Type="layout");
figure; plot(rc, Frequency=freq, Type="directivity");
figure; plot(rc, Frequency=freq, Type="beamwidth");
figure; plot(rc, Frequency=freq, Type="efficiency");
figure; plot(rc, Frequency=freq, Type="patterndata");
```

## Array-Fed (Multi-Beam)

```matlab
rc = reflectorCalculator;
rc.FeedType = "arrayfed";
rc.Diameter = 1;
rc.FocalLength = 0.9;
rc.NumRadiators = 4;
rc.Spacing = 0.012;
rc.RadiatingElement = "conicalhorn";

s = solve(rc, 12e9);
disp(s);
```

## Pattern-Fed (External Data)

```matlab
rc = reflectorCalculator;
rc.FeedType = "patternfed";
rc.FileName = "measured_feed_pattern.csv";  % only .txt and .csv accepted
s = solve(rc, 12e9);
```

## Peak Directivity (Quick Query)

```matlab
dir = peakDirectivity(rc, 12e9);  % returns scalar in dBi
fprintf("Peak directivity: %.2f dBi\n", dir);
```

## Bridge to Full-Wave: createAntenna

`createAntenna` converts the calculator to a `customDualReflectors` for full-wave verification:

```matlab
ant = createAntenna(rc, 12e9);  % returns customDualReflectors
figure; show(ant);
figure; pattern(ant, 12e9);
```

## Solve Output Metrics

`solve(rc, freq)` returns an 18-row table including:
- Focal length, diameter, clearance height (in lambda)
- Feed tilt angle, half-angle subtended, edge angles
- **Efficiency (%)** -- includes illumination + spillover + taper
- **Peak directivity and gain (dBi)** -- at boresight and scan angle
- **Half-power beamwidth (deg)**
- **First sidelobe level (dB)**
- Illumination taper, scan loss, surface RMS loss, feed loss

## When to Use reflectorCalculator vs. reflectorParabolic

| | `reflectorCalculator` | `reflectorParabolic` |
|---|---|---|
| Method | Gaussian-beam (analytical) | Full-wave MoM-PO |
| Speed | Instant | Minutes to hours |
| Accuracy | Good for initial design | High (includes diffraction) |
| Outputs | Metrics table, plots | Full 3D pattern, impedance, S-params |
| Use case | Trade studies, sizing, feed selection | Final verification, near-field |

**Recommended workflow:** Use `reflectorCalculator` for rapid design iteration, then `createAntenna` to generate a `customDualReflectors` for full-wave validation.

----

Copyright 2026 The MathWorks, Inc.
