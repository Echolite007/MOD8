# Passive Dielectric Bodies in conformalArray

`shape` objects with a `.Dielectric` property can be placed directly as elements in `conformalArray` -- no feed is required. They act as passive dielectric scatterers in the full-wave MoM solver.

## Key Behavior

- The `shape` object does NOT need to be wrapped in `customAntenna` (which rejects feedless or pure-dielectric shapes).
- The solver includes the dielectric body in the MoM problem -- efficiency drops below 100%, confirming dielectric loss is modeled.
- `EHfields` returns physically correct internal fields inside the dielectric volume.

## Creating a 3D Dielectric Shape

```matlab
% From a surface triangulation (e.g., human head phantom)
load humanheadcoarse.mat   % provides P (vertices), T (tetrahedra)
scaleFactor = 0.003;
pts = scaleFactor * P;
pts = pts * (0.18 / (max(pts(:,1)) - min(pts(:,1))));  % scale to 180mm

TR = triangulation(T, pts);
[surfFaces, surfVertices] = freeBoundary(TR);
headTri = triangulation(surfFaces, surfVertices);

headShape = shape.Custom3D(headTri);
headShape.Dielectric = "TMM10";  % catalog material
```

## Placing in conformalArray

```matlab
freq = 2.4e9;
d = design(dipole, freq);

arr = conformalArray;
arr.Element = {d, headShape};
arr.ElementPosition = [0.10 0 0; 0 0 0];  % antenna offset from body
arr.Reference = "origin";

figure;
show(arr);
figure;
pattern(arr, freq);

% Internal E-fields for SAR computation
[E, ~] = EHfields(arr, freq, obsPoints');  % 3-by-M input
```

## Dielectric Material Limitation

The `shape.Dielectric` property accepts any material name from `DielectricCatalog`, but the `dielectric` class enforces `LossTangent <= 0.03` at analysis time. High-loss materials (e.g., biological tissue with tanD > 0.03) cannot be used. Use TMM10 (er=9.8, tanD=0.0022) as the highest-permittivity catalog option.

## Use Cases

- **SAR estimation:** Antenna near dielectric tissue phantom (see SAR skill)
- **Radome effects:** Antenna enclosed in dielectric shell
- **Antenna-near-body:** Wearable device proximity to dielectric volume
- **Dielectric loading:** Effect of nearby dielectric on antenna impedance/pattern

----

Copyright 2026 The MathWorks, Inc.
