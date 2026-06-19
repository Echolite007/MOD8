# Custom Antenna Topology Templates

Complete code templates for common custom antenna designs using `customAntenna` and `shape.*` primitives.

## 1. Rectangular Horn Antenna

Waveguide section + tapered flare, fed by a coaxial probe using `FeedShape`. The waveguide runs along x, with the horn opening at +x.

```matlab
f0 = 10e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Waveguide dimensions from design() ---
w = waveguide;
ref = design(w, f0);
wgW = round(ref.Width, 4);      % broad wall (y-axis)
wgH = round(ref.Height, 4);     % narrow wall (z-axis)
wgL = 3 * lambda;               % waveguide length (>= 3*lambda)

% --- Horn flare ---
flareL = 50e-3;
scaleW = 2.0;        % broad-wall flare ratio (y-axis)
scaleH = 2.5;        % narrow-wall flare ratio (z-axis)

% --- Step 1: Waveguide box along x, open face for horn aperture ---
wg = shape.Box(Length=wgL, Width=wgW, Height=wgH);
% Use removeFaces(wg) interactively first to find the +x face index,
% then call removeFaces with that index. Face numbering varies.
removeFaces(wg, 5);

% --- Step 2: Horn flare (extrude WG cross-section, rotate to +x) ---
% Rectangle dims are swapped: Length=wgH maps to X (becomes Z after rotateY),
% Width=wgW maps to Y (stays Y). This ensures the flare cross-section
% matches the waveguide opening (wgW along Y, wgH along Z).
flareRect = shape.Rectangle(Length=wgH, Width=wgW);
hornFlare = extrudeLinear(flareRect, flareL, Scale=[scaleH scaleW], ...
    NumSegments=1, Caps=false);
% rotateY(90) maps z -> +x: base at x=0, wide end at x=+flareL
rotateY(hornFlare, 90);
translate(hornFlare, [wgL/2 0 0]);

% --- Step 3: Combine ---
antShape = wg + hornFlare;

figure; show(antShape);

% --- Step 4: Feed probe (FeedShape for waveguide excitation) ---
probeH = wgH * 0.65;                 % ~65% of narrow wall height
probeW = 5.2e-5;                     % probe width (very thin)
feedX = -wgL/2 + lambda/4;           % lambda/4 from back wall
wallZ = -wgH/2;                      % bottom wall z-position

feedrect = shape.Rectangle(Length=probeH, Width=probeW);
translate(feedrect, [feedX, 0, wallZ + probeH/2]);
rotate(feedrect, 90, ...
    [feedX, 0, wallZ + probeH/2], ...
    [feedX, 1, wallZ + probeH/2]);

ant = customAntenna(Shape=antShape);
createFeed(ant, [feedX, 0, wallZ], 1, FeedShape=feedrect);

% --- Step 5: Mesh and analyze ---
mesh(ant, MaxEdgeLength=lambda/10, MinEdgeLength=lambda/40);

Z = impedance(ant, f0);
fprintf("=== Rectangular Horn ===\n");
fprintf("Impedance at %.1f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));

freqRange = linspace(f0*0.8, f0*1.2, 21);
try
    s = sparameters(ant, freqRange, SweepOption="interp");
catch
    s = sparameters(ant, freqRange);
end
figure; rfplot(s);

figure; pattern(ant, f0);
```

**Design notes:**
- **Use `FeedShape` for waveguide feeds.** A bare point feed gives near-zero impedance.
- The FeedShape probe is a thin rectangle rotated perpendicular to the bottom wall.
- Use `design(waveguide, freq)` to get proper cross-section dimensions.
- Waveguide length must be >= 3*lambda for mode development.
- **Flare cross-section alignment:** Rectangle for `extrudeLinear` must have `Length=wgH, Width=wgW` (swapped vs Box). After `rotateY(90)`, the extrusion z-axis maps to +x.
- **Rotation direction matters:** `rotateY(90)` maps z->+x. `rotateY(-90)` would point backwards.
- Probe height (~50-70% of narrow wall) controls coupling strength.

## 2. Conical Horn

Two approaches: `extrudeLinear` (simpler for uniform-wall cones) and `extrudeRotate` (for variable wall profiles).

### 2a. extrudeLinear approach (preferred for simple cones)

```matlab
f0 = 10e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Dimensions ---
wgRadius = 5e-3;         % circular waveguide radius
apertureRadius = 20e-3;  % horn aperture radius
flareL = 50e-3;          % flare length
wgLength = 3 * lambda;   % waveguide length (>= 3*lambda)

% --- Step 1: Conical horn flare (extrudeLinear with scale) ---
flareCirc = shape.Circle(Radius=wgRadius, NumPoints=24);
hornFlare = extrudeLinear(flareCirc, flareL, ...
    Scale=apertureRadius/wgRadius, Caps=false);

% --- Step 2: Circular waveguide section ---
wgCirc = shape.Circle(Radius=wgRadius, NumPoints=24);
wgSection = extrudeLinear(wgCirc, wgLength, Caps=false);
rotate(wgSection, 180, [0 0 0], [1 0 0]);

% --- Step 3: Back wall with circular feed probe ---
feedRadius = 2e-3;
numPoints = 20;
probeH = wgRadius * 0.65;

backWall = shape.Circle(Radius=wgRadius, NumPoints=24);
feedCirc = shape.Circle(Radius=feedRadius, NumPoints=numPoints);
backWallWithProbe = extrude(backWall, feedCirc, Height=probeH);
translate(backWallWithProbe, [0 0 -wgLength]);

% --- Step 4: Combine ---
antShape = hornFlare + wgSection + backWallWithProbe;

figure; show(antShape);

% --- Step 5: Create antenna and feed ---
ant = customAntenna(Shape=antShape);
createFeed(ant, [0 0 -wgLength], numPoints);

% --- Step 6: Mesh and analyze ---
mesh(ant, MaxEdgeLength=lambda/10, MinEdgeLength=lambda/40);

Z = impedance(ant, f0);
fprintf("=== Conical Horn ===\n");
fprintf("Impedance at %.1f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));

figure; pattern(ant, f0);
```

### 2b. extrudeRotate approach (for variable wall profiles)

Use when wall thickness varies along the horn, or for corrugated/stepped profiles.

```matlab
f0 = 10e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

wgRadius = 5e-3;
apertureRadius = 20e-3;
flareL = 50e-3;
wallThick = 1e-3;
wgLength = 3 * lambda;

% --- Horn flare profile (trapezoid in XY plane) ---
profile = shape.Polygon(Vertices=[
    wgRadius, 0, 0;
    wgRadius + wallThick, 0, 0;
    apertureRadius + wallThick, flareL, 0;
    apertureRadius, flareL, 0]);
hornShape = extrudeRotate(profile, 360, NumSegments=24);

% --- Circular waveguide section ---
wgProfile = shape.Polygon(Vertices=[
    wgRadius, 0, 0;
    wgRadius + wallThick, 0, 0;
    wgRadius + wallThick, -wgLength, 0;
    wgRadius, -wgLength, 0]);
wgSection = extrudeRotate(wgProfile, 360, NumSegments=24);

antShape = hornShape + wgSection;
figure; show(antShape);

ant = customAntenna(Shape=antShape);
createFeed(ant, [wgRadius + wallThick/2, 0, -wgLength], 1);

mesh(ant, MaxEdgeLength=lambda/10, MinEdgeLength=lambda/40);
Z = impedance(ant, f0);
fprintf("=== Conical Horn (extrudeRotate) ===\n");
fprintf("Impedance at %.1f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));

figure; pattern(ant, f0);
```

**Design notes:**
- `extrudeRotate` revolves a 2D polygon around the z-axis. Polygon y-coordinate maps to z-axis in 3D.
- `NumSegments` controls angular smoothness (16-24 for circular).
- **Feed limitation:** Bare point feeds on circular waveguides give poor coupling. `FeedShape` probes fail on curved surfaces. For well-matched circular horns, consider the catalog `horn` antenna or STL import.

## 3. Custom Planar Antenna (2D Shapes)

Cross-shaped slot antenna example.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

gndSize = 100e-3;
slotL = 50e-3;
slotW = 3e-3;

ground = shape.Rectangle(Length=gndSize, Width=gndSize);
hSlot = shape.Rectangle(Length=slotL, Width=slotW);
vSlot = shape.Rectangle(Length=slotW, Width=slotL);

crossSlot = hSlot + vSlot;
slottedGround = createHole(ground, crossSlot);

figure; show(slottedGround);

ant = customAntenna(Shape=slottedGround);
createFeed(ant, [slotW/2, 0, 0], 1);

mesh(ant, MaxEdgeLength=lambda/10);

Z = impedance(ant, f0);
fprintf("=== Cross-Slot Antenna ===\n");
fprintf("Impedance at %.2f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));

freqRange = linspace(f0*0.8, f0*1.2, 21);
try
    s = sparameters(ant, freqRange, SweepOption="interp");
catch
    s = sparameters(ant, freqRange);
end
figure; rfplot(s);
figure; pattern(ant, f0);
```

## 4. Patch Antenna on Substrate

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

subH = 1.6e-3;
patchL = 28e-3;
patchW = 36e-3;
gndSize = 80e-3;

% --- Ground with imprint at feed point ---
feedOffset = patchL/4;
feedWidth = 1.3e-3;  % SMA pin diameter
gnd = shape.Rectangle(Length=gndSize, Width=gndSize);
imprintRect = shape.Rectangle(Length=feedWidth/sqrt(2), Width=feedWidth/sqrt(2));
rotateZ(imprintRect, 45);
translate(imprintRect, [feedOffset, 0, 0]);
gnd = imprintShape(gnd, imprintRect);

% --- Patch raised to substrate height ---
patch = shape.Rectangle(Length=patchL, Width=patchW);
translate(patch, [0 0 subH]);
metalShape = gnd + patch;

% --- Dielectric substrate + air bounding box ---
substrate = shape.Box(Length=gndSize, Width=gndSize, Height=subH, ...
    Center=[0 0 subH/2], Dielectric="FR4");
bbox = shape.Box(Length=3*gndSize, Width=3*gndSize, Height=2*gndSize, ...
    Center=[0 0 gndSize], Dielectric="Air", Transparency=0.1);
subShape = substrate + bbox;

antShape = addSubstrate(metalShape, subShape);

ant = customAntenna(Shape=antShape);

% --- Probe feed with FeedShape (controls feed edge width) ---
feedProbe = shape.Rectangle(Length=feedWidth, Width=subH);
translate(feedProbe, [feedOffset, 0, subH/2]);
rotate(feedProbe, 90, [feedOffset, 0, subH/2], [feedOffset+1, 0, subH/2]);
createFeed(ant, [feedOffset, 0, 0], 1, FeedShape=feedProbe);

mesh(ant, MaxEdgeLength=lambda/8);

Z = impedance(ant, f0);
fprintf("=== Patch on FR4 Substrate ===\n");
fprintf("Impedance at %.2f GHz: %.2f + j%.2f ohm\n", f0/1e9, real(Z), imag(Z));

freqRange = linspace(f0*0.8, f0*1.2, 21);
try
    s = sparameters(ant, freqRange, SweepOption="interp");
catch
    s = sparameters(ant, freqRange);
end
figure; rfplot(s);
figure; pattern(ant, f0);
```

## 5. STL Import Workflow

```matlab
f0 = 5.8e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

ant = customAntennaStl;
ant.FileName = "my_antenna.stl";
ant.Units = "mm";

figure; show(ant);

createFeed(ant, [0 0 0], 1);

mesh(ant, MaxEdgeLength=lambda/6, MinEdgeLength=lambda/30);

Z = impedance(ant, f0);
fprintf("Impedance: %.2f + j%.2f ohm\n", real(Z), imag(Z));
figure; pattern(ant, f0);
```

### Import Triangulated Mesh as Custom3D

```matlab
vertices = [0 0 0; 1 0 0; 0 1 0; 0 0 1];
faces = [1 2 3; 1 2 4; 1 3 4; 2 3 4];
tr = triangulation(faces, vertices);
custom = shape.Custom3D(tr);
show(custom);
```

## 6. Utility Patterns

### Sliver Removal

Boolean operations can produce missing geometry artifacts. Use `removeSlivers`:

```matlab
s1 = shape.Rectangle(Length=20e-3, Width=20e-3);
s2 = shape.Rectangle(Length=10e-3, Width=5e-3);
translate(s1, [s1.Length/2 0 0]);
translate(s2, [-s2.Length/2 0 0]);
sh = s1 + s2;
sh = removeSlivers(sh, 1e-6);
show(sh);
```

### addSubstrate with 2D Metal Shape

`addSubstrate` requires a 3D metal shape. Convert 2D shapes using `shape.Custom3D`:

```matlab
rect = shape.Rectangle(Length=0.05, Width=0.05);
translate(rect, [0.025 0 0.005]);
met3d = shape.Custom3D(Vertices=getShapeVertices(rect));
sub = shape.Box(Length=0.1, Width=0.1, Height=0.01, Dielectric="FR4");
metalSub = addSubstrate(met3d, sub);
```

### RetainShape Behavior

```matlab
% RetainShape=true: retains portion of second shape inside first
add(box1, box2, RetainShape=true);
% RetainShape=false: does not retain internal portion
add(box1, box2, RetainShape=false);
```

### Color Change in Shapes

```matlab
s1 = shape.Box(Center=[0 0 1]);
s2 = shape.Box(Center=[0 0 4]);
rs1 = s1 + s2;
rs1.Color = "r";
show(rs1, EnableIndividualColors=false);
```

----

Copyright 2026 The MathWorks, Inc.
