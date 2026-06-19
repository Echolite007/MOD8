# PCB Antenna Topology Templates

Complete code templates for common PCB antenna designs using `pcbStack`. Each template is self-contained and ready to run -- adjust dimensions and frequency to your requirements.

## 1. Probe-Fed Microstrip Patch

The simplest PCB antenna. A rectangular patch on a grounded substrate, excited by a coaxial probe.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Substrate ---
subHeight = 1.6e-3;
sub = dielectric("FR4");

% --- Dimensions (start from catalog design, then customize) ---
ant0 = design(patchMicrostrip, f0);
patchL = ant0.Length;
patchW = ant0.Width;
gndL = ant0.GroundPlaneLength;
gndW = ant0.GroundPlaneWidth;
feedX = ant0.FeedOffset(1);

% --- Shapes ---
patch = antenna.Rectangle(Length=patchL, Width=patchW);
ground = antenna.Rectangle(Length=gndL, Width=gndW);
board = antenna.Rectangle(Length=gndL, Width=gndW);

% --- Assemble ---
p = pcbStack;
p.BoardShape = board;
p.BoardThickness = subHeight;
p.Layers = {patch, sub, ground};
p.FeedLocations = [feedX, 0, 1, 3];
p.FeedDiameter = 1e-3;
p.Conductor = metal("Copper");

% --- Visualize ---
figure; show(p);
figure; layout(p);

% --- Analyze ---
freqRange = linspace(f0*0.8, f0*1.2, 31);
figure; impedance(p, freqRange);

try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);

Z = impedance(p, f0);
bw = bandwidth(p, freqRange);
fprintf("Impedance at %.2f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));
fprintf("Bandwidth (-10 dB): %.2f MHz\n", bw/1e6);
```

**Design notes:**
- Feed offset from center controls impedance: closer to center = lower impedance, closer to edge = higher impedance. Target ~50 ohm.
- Ground plane is typically 2-3x the patch size.
- FR4 is lossy at higher frequencies -- switch to RO4003C or similar above 5 GHz.

## 2. Microstrip-Fed Wide Slot Antenna

A slot cut in the ground plane, excited by a microstrip feed line on the opposite side. Wideband performance.

```matlab
f0 = 1.8e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Parameters ---
subHeight = 0.8e-3;
sub = dielectric("FR4");

gndSize = 110e-3;
slotL = 60e-3;
slotW = 3e-3;
traceW = 1.5e-3;       % microstrip width (tune for 50 ohm)
traceL = 50e-3;         % microstrip length (extends to board edge)
board = antenna.Rectangle(Length=gndSize, Width=gndSize);

% --- Top layer: microstrip feed line ---
feedLine = antenna.Rectangle(Length=traceW, Width=traceL, Center=[0, -gndSize/2+traceL/2]);

% --- Bottom layer: ground with slot ---
ground = antenna.Rectangle(Length=gndSize, Width=gndSize);
slot = antenna.Rectangle(Length=slotL, Width=slotW);
slottedGround = ground - slot;

% --- Assemble ---
p = pcbStack;
p.BoardShape = board;
p.BoardThickness = subHeight;
p.Layers = {feedLine, sub, slottedGround};
p.FeedLocations = [0, -gndSize/2, 1, 3];   % edge feed
p.FeedDiameter = traceW / 2;

% --- Visualize ---
figure; show(p);
figure; layout(p);

% --- Analyze ---
freqRange = linspace(f0*0.6, f0*1.4, 41);
try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);

Z = impedance(p, f0);
fprintf("Impedance at %.2f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));
```

**Design notes:**
- Slot length ~ lambda/2 at the operating frequency.
- Feed line crosses perpendicular to the slot for maximum coupling.
- Wideband: 30-50% bandwidth typical for wide slots.
- Bidirectional radiation pattern (radiates both sides).

## 3. Aperture-Coupled Patch (5-Layer Stack)

A patch on the top substrate coupled through a slot in the middle ground plane, fed by a microstrip on the bottom substrate. Best isolation between feed network and radiator.

```matlab
f0 = 5.8e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Substrates ---
upperSubH = 0.8e-3;     % radiator substrate (thicker = wider BW)
lowerSubH = 0.5e-3;     % feed substrate (thin for controlled impedance)

upperSub = dielectric(Name="RO4003C", EpsilonR=3.55, LossTangent=0.0027, Thickness=upperSubH);
lowerSub = dielectric(Name="RO4003C", EpsilonR=3.55, LossTangent=0.0027, Thickness=lowerSubH);

% --- Dimensions ---
gndSize = 40e-3;
patchL = 12e-3;
patchW = 12e-3;
slotL = 8e-3;
slotW = 1e-3;
traceW = 1.2e-3;
stubL = 4e-3;            % open stub past slot center

% --- Layer shapes ---
radiator = antenna.Rectangle(Length=patchL, Width=patchW);

ground = antenna.Rectangle(Length=gndSize, Width=gndSize);
slot = antenna.Rectangle(Length=slotL, Width=slotW);
slottedGround = ground - slot;

% Feed line with open stub
feedLine = antenna.Rectangle(Length=traceW, Width=20e-3, Center=[0, -gndSize/2+10e-3]);
stub = antenna.Rectangle(Length=traceW, Width=stubL, Center=[0, stubL/2]);
feedWithStub = feedLine + stub;

board = antenna.Rectangle(Length=gndSize, Width=gndSize);

% --- Assemble 5-layer stack ---
p = pcbStack;
p.BoardShape = board;
p.BoardThickness = upperSubH + lowerSubH;
p.Layers = {radiator, upperSub, slottedGround, lowerSub, feedWithStub};
% Indices: radiator=1, upperSub=2, ground=3, lowerSub=4, feed=5
p.FeedLocations = [0, -gndSize/2, 5, 3];   % sig=feed(5), gnd=ground(3)
p.FeedDiameter = traceW / 2;

% --- Visualize ---
figure; show(p);
figure; layout(p);

% --- Analyze ---
freqRange = linspace(f0*0.85, f0*1.15, 31);
try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);
```

**Design notes:**
- Slot length ~ 0.4 * lambda_guided controls coupling strength.
- Open stub length past the slot tunes the reactive part of impedance.
- This topology has the best feed isolation and is ideal for arrays.
- `BoardThickness` = sum of both substrates.
- Feed connects layer 5 (bottom metal) to layer 3 (middle ground).

## 4. Corner-Truncated Patch for Circular Polarization

A square patch with two diagonally opposite corners truncated to excite two orthogonal modes with 90-degree phase offset. Single-feed CP.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Substrate ---
subHeight = 1.6e-3;
epsR = 4.4;
sub = dielectric("FR4");

% --- Patch dimensions ---
% Square patch slightly larger than resonant length to split modes
Lp = 0.49 * lambda / sqrt(epsR);    % nominal resonant size
Lp = Lp * 1.02;                      % slightly enlarge for mode splitting

% Truncation size: 14-17% of patch side for optimal axial ratio
tc = 0.155 * Lp;

% --- Build corner-truncated patch ---
patch = antenna.Rectangle(Length=Lp, Width=Lp);
tri1 = antenna.Polygon(Vertices=[Lp/2, Lp/2, 0; Lp/2-tc, Lp/2, 0; Lp/2, Lp/2-tc, 0]);
tri2 = antenna.Polygon(Vertices=[-Lp/2, -Lp/2, 0; -Lp/2+tc, -Lp/2, 0; -Lp/2, -Lp/2+tc, 0]);
cpPatch = patch - tri1 - tri2;

% --- Ground and board ---
gndSize = 3 * Lp;
ground = antenna.Rectangle(Length=gndSize, Width=gndSize);
board = antenna.Rectangle(Length=gndSize, Width=gndSize);

% --- Assemble ---
p = pcbStack;
p.BoardShape = board;
p.BoardThickness = subHeight;
p.Layers = {cpPatch, sub, ground};
p.FeedLocations = [Lp/4, 0, 1, 3];    % offset feed along diagonal
p.FeedDiameter = 1e-3;

% --- Visualize ---
figure; show(p);

% --- Analyze ---
freqRange = linspace(f0*0.9, f0*1.1, 31);
try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);

% Axial ratio
figure; axialRatio(p, f0, 0, 0:1:90);
```

**Design notes:**
- Truncation creates LHCP or RHCP depending on which diagonal corners are cut.
- Cutting top-right and bottom-left → RHCP; top-left and bottom-right → LHCP.
- Truncation size is critical: too small = poor CP, too large = poor matching. Start at 15.5% of patch side.
- Axial ratio < 3 dB defines the CP bandwidth (typically narrower than impedance BW).

## 5. Dual-Feed Patch for Circular Polarization

Two orthogonal feeds with 90-degree phase offset on a square patch. Wider axial ratio bandwidth than single-feed CP.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Substrate ---
subHeight = 1.6e-3;
epsR = 4.4;
sub = dielectric("FR4");

% --- Square patch ---
Lp = 0.49 * lambda / sqrt(epsR);
patch = antenna.Rectangle(Length=Lp, Width=Lp);

gndSize = 3 * Lp;
ground = antenna.Rectangle(Length=gndSize, Width=gndSize);
board = antenna.Rectangle(Length=gndSize, Width=gndSize);

% --- Assemble with dual feeds ---
p = pcbStack;
p.BoardShape = board;
p.BoardThickness = subHeight;
p.Layers = {patch, sub, ground};

% Two orthogonal feeds
feedOffset = Lp / 4;
p.FeedLocations = [feedOffset, 0, 1, 3;     % feed 1: along x
                   0, feedOffset, 1, 3];     % feed 2: along y
p.FeedDiameter = 1e-3;
p.FeedVoltage = [1, 1];
p.FeedPhase = [0, 90];     % 90 deg for RHCP; use -90 for LHCP

% --- Visualize ---
figure; show(p);

% --- Analyze ---
freqRange = linspace(f0*0.9, f0*1.1, 31);
try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);
figure; axialRatio(p, f0, 0, 0:1:90);
```

**Design notes:**
- Wider CP bandwidth than corner truncation because the 90-degree phase is enforced externally.
- Requires a 90-degree hybrid coupler in practice (not modeled here).
- S-parameters will show a 2-port network. Check both S11 and S21 (isolation).

## 6. Gerber Export with Edge-Launch SMA

Complete fabrication-ready export for any of the above designs.

```matlab
% Assuming p is an assembled pcbStack with an edge feed...

% --- Manufacturing service ---
W = PCBServices.OSHParkWriter;       % or PCBWayWriter, SeeedWriter, etc.
W.Filename = 'my_antenna_v1';        % MUST be char, not "string"

% --- Edge-launch SMA connector ---
C = PCBConnectors.SMAEdge_Samtec;
C.EdgeLocation = 'south';            % match feed edge
C.ExtendBoardProfile = true;

% --- Generate ---
A = PCBWriter(p, W, C);
A.Soldermask = 'both';
A.PCBMargin = 0.5e-3;
gerberWrite(A);

% --- Or through-hole SMA ---
W2 = PCBServices.OSHParkWriter;
W2.Filename = 'my_antenna_thruhole';
C2 = PCBConnectors.SMA_Cinch;
A2 = PCBWriter(p, W2, C2);
gerberWrite(A2);
```

**Connector selection guide:**
- **Through-hole SMA** (`SMA_Cinch`): Robust, easy to solder, good for prototyping.
- **Edge-launch SMA** (`SMAEdge_Samtec`): Better high-frequency performance, requires feed at board edge.
- **U.FL** (`UFL_Hirose`): Small footprint, good for compact designs and cable connections.

## 7. Parasitic Patch Antenna

A driven patch with parasitic elements on the same metal layer. The parasitic elements couple electromagnetically to widen bandwidth or shape the pattern.

```matlab
f0 = 850e6;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Dimensions ---
L = 0.15;                % driven patch length
W = 1.5 * L;            % driven patch width
stripL = L;             % parasitic element length
gap = 0.015;            % gap between driven and parasitic elements
gndL = 0.55;
gndW = 0.4;
h = 7e-3;               % board thickness (air dielectric)

% --- Shapes ---
driven = antenna.Rectangle(Center=[0 0], Length=L, Width=W);
parasitic1 = antenna.Rectangle(Center=[L/2+stripL/2+gap, 0], Length=stripL, Width=W);
parasitic2 = antenna.Rectangle(Center=[-L/2-stripL/2-gap, 0], Length=stripL, Width=W);
topMetal = driven + parasitic1 + parasitic2;

ground = antenna.Rectangle(Length=gndL, Width=gndW);

% --- Assemble (2-layer: air dielectric assumed) ---
p = pcbStack;
p.BoardShape = ground;
p.BoardThickness = h;
p.Layers = {topMetal, ground};
p.FeedLocations = [L/4, 0, 1, 2];

% --- Visualize ---
figure; show(p);

% --- Analyze ---
freqRange = linspace(f0*0.8, f0*1.2, 31);
figure; impedance(p, freqRange);

try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);
```

**Design notes:**
- Gap between driven and parasitic elements controls coupling strength. Smaller gap = stronger coupling = wider bandwidth but harder to match.
- Parasitic elements are typically similar size to the driven element. Slightly longer/shorter to create staggered resonances for bandwidth enhancement.
- 2-layer stack (no dielectric object) assumes air between metal layers.
- Feed is offset from driven patch center by `L/4` for ~50 ohm match.

## 8. Series-Fed (Direct-Coupled) Patch Array

Multiple patches connected by narrow microstrip strips on a single metal layer. A corporate feed or series feed creates an in-phase array on one PCB.

```matlab
f0 = 850e6;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Dimensions ---
L = lambda / 2;          % patch length
W = lambda / 2;          % patch width
spacing = lambda * 0.8;  % center-to-center patch spacing
stripLen = spacing - L;  % connecting strip length
stripW = 0.02 * lambda;  % connecting strip width (narrow)
gndL = 3 * spacing;
gndW = 0.4;
h = 7e-3;

% --- Shapes: three patches joined by strips ---
p1 = antenna.Rectangle(Length=L, Width=W);
p2 = antenna.Rectangle(Length=L, Width=W, Center=[spacing, 0]);
p3 = antenna.Rectangle(Length=L, Width=W, Center=[-spacing, 0]);
strip1 = antenna.Rectangle(Length=stripLen, Width=stripW, Center=[spacing/2, 0]);
strip2 = antenna.Rectangle(Length=stripLen, Width=stripW, Center=[-spacing/2, 0]);
seriesFed = p1 + p2 + p3 + strip1 + strip2;

ground = antenna.Rectangle(Length=gndL, Width=gndW);

% --- Assemble (2-layer: air dielectric assumed) ---
p = pcbStack;
p.BoardShape = ground;
p.BoardThickness = h;
p.Layers = {seriesFed, ground};
p.FeedLocations = [L/4, 0, 1, 2];

% --- Visualize ---
figure; show(p);

% --- Analyze ---
freqRange = linspace(f0*0.8, f0*1.2, 31);
figure; impedance(p, freqRange);

try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);
```

**Design notes:**
- Strip width controls impedance of the connecting transmission line. Narrow strips (~0.02*lambda) act as high-impedance lines.
- Patch spacing affects mutual coupling and array factor. Typical: 0.7-1.0 lambda center-to-center.
- Feed the center patch for symmetric excitation; feed an end patch for traveling-wave behavior.
- 2-layer stack (no dielectric object) assumes air between metal layers.
- For substrate-backed versions, add a dielectric layer: `p.Layers = {seriesFed, sub, ground}`.

## 9. Probe-Fed Stacked Patch (Wideband)

Two patches of slightly different sizes stacked vertically, separated by dielectric layers. Dual resonance gives wideband performance (25%+ bandwidth).

```matlab
f0 = 7.5e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Dimensions ---
L1 = 15e-3;   W1 = 16e-3;    % lower patch (larger, lower resonance)
L2 = 13.5e-3; W2 = 12.5e-3;  % upper patch (smaller, upper resonance)
Lgnd = 3 * L2;
Wgnd = Lgnd;

% --- Substrates ---
d1 = 1.524e-3;   % lower substrate thickness
d2 = 2.5e-3;     % upper substrate thickness

dL = dielectric;
dL.EpsilonR = 2.2;
dL.Thickness = d1;

dU = dielectric;
dU.EpsilonR = 1.07;
dU.Thickness = d2;

% --- Shapes ---
pU = antenna.Rectangle(Length=L2, Width=W2);     % upper patch
pL = antenna.Rectangle(Length=L1, Width=W1);     % lower patch
pGnd = antenna.Rectangle(Length=Lgnd, Width=Wgnd);

% --- Assemble 5-layer stack ---
p = pcbStack;
p.BoardShape = pGnd;
p.BoardThickness = d1 + d2;
p.Layers = {pU, dU, pL, dL, pGnd};
% Indices: upperPatch=1, upperSub=2, lowerPatch=3, lowerSub=4, ground=5
p.FeedLocations = [5.4e-3, 0, 3, 5];   % probe to lower patch, gnd=5
p.FeedDiameter = 1.3e-3;
p.FeedViaModel = "square";

% --- Visualize ---
figure; show(p);
figure; layout(p);

% --- Analyze ---
freqRange = linspace(f0*0.7, f0*1.3, 41);
mesh(p, MaxEdgeLength=0.01, MinEdgeLength=0.003);
figure; impedance(p, freqRange);

try
    s = sparameters(p, freqRange, SweepOption="interp");
catch
    s = sparameters(p, freqRange);
end
figure; rfplot(s);

figure; pattern(p, f0);
```

**Design notes:**
- Lower patch is larger (lower resonance), upper patch is smaller (higher resonance). The two resonances merge for wideband operation.
- Upper substrate should be low permittivity (foam or air) for wider bandwidth.
- Probe feeds the lower patch (layer 3), not the upper patch — coupling to the upper patch is electromagnetic.
- `BoardThickness` = sum of both dielectric thicknesses.
- `FeedViaModel = "square"` gives a better approximation of a solid probe column.
- Use `MinEdgeLength` in `mesh()` for multi-layer structures with fine features.

----

Copyright 2026 The MathWorks, Inc.
