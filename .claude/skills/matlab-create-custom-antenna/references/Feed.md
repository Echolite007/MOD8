# Geometry and Feed Examples

Examples demonstrating how to build custom antenna geometries from `shape.*` primitives and configure feeds using `createFeed`.

## 1. Dipole with Imprinted Feed

Creates a dipole from a `shape.Rectangle` with an imprinted diamond-shaped feed region to control feed width precisely.

```matlab
d1 = dipole;
rect1 = shape.Rectangle('Length',d1.Length,'Width',d1.Width);

% Imprint a diamond at the center to control feed edge width
imprint_rect = shape.Rectangle('Length',d1.Width/sqrt(2),'Width',d1.Width/sqrt(2));
rotateZ(imprint_rect, 45);
rect1 = imprintShape(rect1, imprint_rect);

% Rotate into 3D orientation
rotateY(rect1, 90);

ant = customAntenna('Shape', rect1);
createFeed(ant, [0 0 0], 1);
show(ant);

mesh(ant, 'MaxEdgeLength', 0.1);
pattern(ant, 70e6);
impedance(ant, linspace(60e6, 90e6, 30));
```

**Key points:**
- Without the imprint, the coarse mesh may select a feed edge wider than intended.
- The imprint diamond (rotated 45 deg, diagonal = strip width) forces the mesher to create an edge of the correct width at the feed point.
- Single-edge feed (`numEdges=1`) is appropriate for strip-type dipoles.

## 2. Cylindrical Monopole (Circular Feed)

Demonstrates circular feed creation using `extrude` to attach a cylinder to a ground plane.

```matlab
feed_loc = [-1.8 -1.8 0];
m1 = monopoleCylindrical("GroundPlaneLength",4,'GroundPlaneWidth',4, ...
    'FeedOffset',[feed_loc(1) feed_loc(2)]);

% Ground plane
sh1 = shape.Rectangle('Length',m1.GroundPlaneLength,'Width',m1.GroundPlaneWidth);

% Circular cross-section for the monopole
feed_circ = shape.Circle('Radius',m1.Radius,'NumPoints',20);
translate(feed_circ, feed_loc);

% Extrude the circle on the ground plane
sh1 = extrude(sh1, feed_circ, 'Height', m1.Height);

ant = customAntenna('Shape', sh1);
% NumEdges matches the number of polygon points on the cylinder base
createFeed(ant, feed_loc, 20);
show(ant);

mesh(ant, 'MaxEdgeLength', 0.1);
pattern(ant, 60e6);
```

**Key points:**
- `NumPoints` on the circle controls the polygon resolution (20 = 20-sided polygon).
- `numEdges` in `createFeed` must match `NumPoints` so the feed ring spans the full cylinder-ground junction.
- Use `extrude` to grow a 2D profile out of an existing surface, creating shared edges at the junction.

## 3. Strip Monopole (Single-Edge Feed)

Builds a rectangular monopole on a ground plane with a single-edge feed at the base.

```matlab
m2 = monopole;
gnd = shape.Rectangle('Length',m2.GroundPlaneLength,'Width',m2.GroundPlaneWidth);

% Imprint diamond at feed point for controlled feed width
imprint_rect = shape.Rectangle('Length',m2.Width/sqrt(2),'Width',m2.Width/sqrt(2));
rotateZ(imprint_rect, 45);
gnd = imprintShape(gnd, imprint_rect);

% Create and position the monopole strip
monopole_rect = shape.Rectangle('Length',m2.Height,'Width',m2.Width);
rotateY(monopole_rect, 90);
translate(monopole_rect, [0 0 monopole_rect.Length/2]);

total_shape = gnd + monopole_rect;
ant = customAntenna('Shape', total_shape);
createFeed(ant, [0 0 0], 1);
show(ant);

mesh(ant, 'MaxEdgeLength', 0.06);
sparameters(ant, linspace(0.8e9, 1.2e9, 20));
```

**Key points:**
- The imprint ensures the feed edge aligns exactly with the monopole strip width.
- The monopole is rotated 90 deg around Y to stand vertically, then translated so its base touches z=0.
- Boolean union (`+`) creates shared edges at the ground-monopole junction.

## 4. Interactive Feed Creation

```matlab
ant = customAntenna('Shape', total_shape);
createFeed(ant);  % Opens interactive GUI for edge selection
```

## 5. Feed Strip Width Control

Shows how to set up a feed of a specific width on a ground plane using the imprint technique.

```matlab
rect = shape.Rectangle("Length",0.05,'Width',0.05);
fw = 0.004;  % desired feed width
feed = shape.Rectangle('Length',0.01,'Width',fw);
rotateY(feed, 90);
translate(feed, [0 0 0.005]);

% Imprint diamond on ground so feed edge matches strip width exactly
imprint_rect = shape.Rectangle("Length",fw/sqrt(2),'Width',fw/sqrt(2));
rotateZ(imprint_rect, 45);
rect_imp = imprintShape(rect, imprint_rect);

total_shape = rect_imp + feed;
ant = customAntenna('Shape', total_shape);
createFeed(ant, [0 0 0], 1);
show(ant);
```

**Key points:**
- The imprint diamond diagonal equals the feed strip width (`fw`), so `Length = Width = fw/sqrt(2)`.
- Always imprint **before** the boolean union with the feed strip.

## 6. Biconical Antenna (Circular Feed, Body of Revolution)

Demonstrates a biconical structure built from cones, spheres, and boolean operations with a multi-edge circular feed.

```matlab
sphereRadius = 0.024;
coneCapRadius = 0.017;
coneHeight = 0.017;
feedHeight1 = 0.5e-3;
feedDia1 = 0.5e-3;

% Upper cone with feed cylinder
cone1 = shape.Cylinder(Cap=[0 0], Height=coneHeight, ...
    Radius=[feedDia1/2 coneCapRadius]);
translate(cone1, [0 0 coneHeight/2 + feedHeight1/2]);

% Small feed cylinder to create a closed loop at the feed gap
feed1 = shape.Cylinder(Cap=[0 0], Height=feedHeight1/2, Radius=feedDia1/2);
translate(feed1, [0 0 feedHeight1/4]);

% Combine and intersect with sphere for shaping
ConeNfeed1 = add(feed1, cone1);
sph1 = shape.Sphere(Radius=sphereRadius);
capShape1 = intersect(ConeNfeed1, sph1);

% Mirror for the bottom half
capShape1Copy = copy(capShape1);
rotate(capShape1Copy, 180, [0 0 0], [0 1 0]);

antShape1 = add(capShape1, capShape1Copy, RetainShape=false);
ant1 = customAntenna(Shape=antShape1);
createFeed(ant1, [0 0 0], 20);
show(ant1);
```

**Key points:**
- The feed cylinder is split in half so top/bottom halves form a closed loop at z=0.
- `NumEdges=20` creates a polygonal ring feed around the circular gap.
- `intersect` with a sphere trims the cones to a spherical envelope.
- `RetainShape=false` in the final union removes internal boundaries between halves.

## Common Feed Patterns Summary

| Antenna Type | Feed Method | `numEdges` |
|---|---|---|
| Strip dipole/monopole | `imprintShape` + `createFeed(ant, loc, 1)` | 1 |
| Cylindrical monopole | `extrude` circle on ground + `createFeed(ant, loc, N)` | Matches `NumPoints` |
| Body of revolution | `createFeed(ant, loc, N)` with large N | 16--24 |
| Waveguide/horn | `createFeed(ant, loc, 1, FeedShape=probe)` | 1 |
| Interactive | `createFeed(ant)` | Selected in GUI |

----

Copyright 2026 The MathWorks, Inc.
