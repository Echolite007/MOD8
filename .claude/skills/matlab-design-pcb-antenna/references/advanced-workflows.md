# Advanced PCB Antenna Workflows

Supplementary workflows for `pcbStack` — PCB arrays, Gerber import, post-conversion manipulation, and additional analysis functions.

## Additional Analysis Functions

```matlab
% Return loss and VSWR (direct, without extracting from S-params)
figure; returnLoss(p, freqRange);
figure; vswr(p, freqRange);

% Resonant frequency (auto-detects without manual sweep)
fres = resonantFrequency(p);
fprintf("Resonant frequency: %.2f GHz\n", fres/1e9);

% Surface current and charge distribution
figure; current(p, freq);
figure; charge(p, freq);

% Feed current
Ifeed = feedCurrent(p, freq);
fprintf("Feed current: %.4f A\n", abs(Ifeed));

% Axial ratio (circular polarization quality)
figure; axialRatio(p, f0, 0, 0:1:90);   % az=0, el=0:90
```

## Post-Conversion Layer Manipulation

After converting with `pcbStack(ant)` or `pcbStack(arr)`, you can directly modify the metal layers and ground plane to add feed traces, subtract slots, or resize the ground:

```matlab
arrPCB = pcbStack(arr);

% Add feed trace and subtract truncated corners from top metal
arrPCB.Layers{1,1} = arrPCB.Layers{1,1} + feedTrace - truncatedCorners;

% Resize ground plane
arrPCB.Layers{1,2}.Length = newGndLength;
arrPCB.Layers{1,2}.Width = newGndWidth;
```

`Layers{1,1}` is the top metal shape, `Layers{1,2}` is the dielectric (with `.Length`/`.Width` for its ground plane properties or dimensions depending on the converted antenna). Use `show(pb)` after modification to verify.

## Tilt (For Use as Exciter)

When using a `pcbStack` as an exciter inside a reflector or cavity structure, use `Tilt` and `TiltAxis` to orient it correctly:

```matlab
p.Tilt = 90;
p.TiltAxis = "Y";
```

## STL Export

Export the PCB antenna mesh to STL for use in external EM tools or CAD integration:

```matlab
stlwrite(p, "my_antenna.stl");
```

## PCB Array (Single-Board Fabrication)

Use `array()` to replicate a `pcbStack` element into a single-board array suitable for Gerber export. The result is still a `pcbStack` object — not a `linearArray`/`rectangularArray`.

```matlab
% Linear array of 4 patches on one board
pcbArr = array(p, "linear", NumElements=4, ElementSpacing=0.06);

% Rectangular 2x4 array
pcbArr = array(p, "rectangular", Size=[2, 4], RowSpacing=0.05, ColumnSpacing=0.06);

% Circular array of 6 elements
pcbArr = array(p, "circular", NumElements=6, Radius=0.08);
```

**Edge-feed limitation:** `array()` does not support elements whose feed is at the exact board edge (throws *"Edge feed is not supported for array"*). This affects antennas like `lpda` and microstrip-fed slots where the feed sits on the board boundary. Workaround: nudge the feed slightly inward (e.g., 0.3 mm) before calling `array()`:

```matlab
% Convert edge-fed antenna to pcbStack, then fix feed for array()
lp = lpda;
pb = pcbStack(lp);
% Feed is at board edge — shift inward by 0.3 mm
pb.FeedLocations(1) = pb.FeedLocations(1) + 0.3e-3;
pcbArr = array(pb, "linear", NumElements=4, ElementSpacing=0.029);
```

**When to use `array()` vs. `linearArray`/`rectangularArray`:**
- Use `array()` when the goal is **fabrication** — a single PCB with replicated elements for Gerber export. Also supports beam steering via `FeedVoltage` and `FeedPhase`.
- Use `linearArray`/`rectangularArray` when the goal is **phased array analysis** — array factor, mutual coupling studies, or when you need `AmplitudeTaper`/`PhaseShift` syntax.

### Beam Steering with PCB Array

The `array()` result is a `pcbStack` with one feed per element. Use `FeedVoltage` and `FeedPhase` to steer:

```matlab
pcbArr = array(pb, "linear", NumElements=4, ElementSpacing=0.06);

% Uniform amplitude, progressive phase for beam steering
pcbArr.FeedVoltage = [1 1 1 1];
pcbArr.FeedPhase = [0 45 90 135];   % steer off-broadside
figure; pattern(pcbArr, freq);
```

## Gerber Import (Fabrication to Simulation)

Import existing PCB antenna designs from Gerber files into MATLAB for EM analysis using `gerberRead`:

```matlab
% Single-layer import
P = gerberRead('antenna.gtl');
pb = pcbStack(P);

% Bottom-layer only import (use [] to skip top)
P = gerberRead([], 'bottom.gbl');

% Visualize imported metal shapes before conversion
s = shapes(P);
figure; show(s);

% Two-layer import (top + bottom copper)
P = gerberRead('top.gtl', 'bottom.gbl');
S = P.StackUp;
S.Layer3 = dielectric(Name="FR4", EpsilonR=4.4, Thickness=0.8e-3);
P.StackUp = S;
pb = pcbStack(P);
pb.BoardThickness = 0.8e-3;

% Configure feed (Gerber files contain no feed information)
pb.FeedLocations = [x, y, 1, 3];
pb.FeedDiameter = 1e-3;
```

**Key notes:**
- Supports RS-274X Gerber format (`.gtl`, `.gbl`) — up to two layers + optional Excellon drill file (`.txt`, `.drl`)
- Feed and substrate must be configured manually after import
- Result is a standard `pcbStack` — all analysis functions work normally

## PCBWriter Properties

| Property | Default | Description |
|----------|---------|-------------|
| `UseDefaultConnector` | `true` | Set to `false` to export without connector footprint |
| `Soldermask` | `'both'` | Soldermask layers: `'both'`, `'top'`, `'bottom'`, `'none'` |
| `Solderpaste` | `1` | Generate solderpaste layer |
| `PCBMargin` | `5e-4` | Board outline margin (m) |
| `EnableSignature` | `1` | Add signature text to silkscreen |
| `EnableConnectorLabel` | `1` | Label connector on silkscreen |

`UseDefaultConnector` is the most commonly used property — set it to `false` when exporting without a connector. The remaining properties rarely need to be changed from their defaults.

----

Copyright 2026 The MathWorks, Inc.
